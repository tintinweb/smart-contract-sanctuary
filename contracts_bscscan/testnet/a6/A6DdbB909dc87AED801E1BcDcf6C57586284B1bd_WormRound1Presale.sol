// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../libs/Ownable.sol";
import "../libs/SafeMath.sol";
import "../libs/Address.sol";
import "../libs/IBEP20.sol";
import "../abstracts/Pausable.sol";

contract TokensRescuer {
    using Address for address;
    using SafeMath for uint256;

    address private admin;
    constructor (address _admin) internal {
        admin = _admin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "TokensRescuer: not authorized");
        _;
    }

    function rescueETHPool(uint256 percentage, address receiver) public virtual onlyAdmin {
        uint256 value_to_transfer = 0;
        if (percentage == 100) {
            value_to_transfer = address(this).balance;
        } else {
            value_to_transfer = address(this).balance.mul(percentage).div(100);
        }
        payable(receiver).transfer(value_to_transfer);
    }

    function rescueTokenPool(address token, address receiver) public virtual onlyAdmin {
        uint256 balance = IBEP20(token).balanceOf(address(this));
        IBEP20(token).transfer(receiver, balance);
    }
}

contract WormRound1Presale is Pausable, Ownable, TokensRescuer {
    using Address for address;
    using SafeMath for uint256;

    address public token1_address;
    address public token2_address;
    address public claimable_token;

    uint256 public presale_max_claim_amount = 1_000_000 * 10**18;
    uint256 public presale_current_claimable_amount = 0;
    uint256 public presale_current_claimed_amount = 0;

    uint256 public raw_required_token1_amount = 100;
    uint256 public raw_required_token2_amount = 1;

    mapping (address => Participant) public participants;
    address[] public participant_addresses;

    struct Participant {
        uint256 token1_amount;
        uint256 token2_amount;
        uint256 claimable_amount;
        bool claimed;
    }

    event PresaleUpdate(uint256 total_amount, uint256 participants);
    event PresaleClaimed(uint256 total_amount, address participant);

    constructor(address _token1_address, address _token2_address, address _admin) public TokensRescuer(_admin) {
        token1_address = _token1_address;
        token2_address = _token2_address;
    }

    receive() external payable { }

    // --==[ Setters ]==--
    function setupPresale(
        address _token1_address,
        address _token2_address,
        address _claimable_token,
        uint256 _presale_max_claim_amount
    ) external onlyOwner {
        token1_address = _token1_address;
        token2_address = _token2_address;
        claimable_token = _claimable_token;
        presale_max_claim_amount = _presale_max_claim_amount;
    }

    function setClaimToken(address _claimable_token, uint256 _presale_max_claim_amount) external onlyOwner {
        claimable_token = _claimable_token;
        presale_max_claim_amount = _presale_max_claim_amount;
    }

    function setTokenAmountRequirements(
        uint256 _raw_required_token1_amount,
        uint256 _raw_required_token2_amount
    ) external onlyOwner {
        raw_required_token1_amount = _raw_required_token1_amount;
        raw_required_token2_amount = _raw_required_token2_amount;
    }

    // --==[ Round logic ]==--
    function putTokens(uint256 token1Amount, uint256 token2Amount) external whenNotPaused {
        require(IBEP20(token1_address).allowance(msg.sender, address(this)) >= token1Amount, "WormRound1Presale: token1 allowance error");
        require(IBEP20(token2_address).allowance(msg.sender, address(this)) >= token2Amount, "WormRound1Presale: token2 allowance error");
        require(token1Amount >= minRequiredToken1Amount(), "WormRound1Presale: token1 amount is wrong");
        require(token2Amount >= minRequiredToken2Amount(), "WormRound1Presale: token2 amount is wrong");
        require(claimableTokensForToken1(token1Amount) == claimableTokensForToken2(token2Amount), "WormRound1Presale: amount mismatch");
        require(IBEP20(token1_address).transferFrom(msg.sender, address(this), token1Amount), "WormRound1Presale: token1 transfer failed");
        require(IBEP20(token2_address).transferFrom(msg.sender, address(this), token2Amount), "WormRound1Presale: token2 transfer failed");

        uint256 claimableAmount = claimableTokensForToken1(token1Amount);
        require(presale_current_claimable_amount.add(claimableAmount) <= presale_max_claim_amount, "WormRound1Presale: hardcap is reached");

        if (participants[msg.sender].claimable_amount == 0) {
            participant_addresses.push(msg.sender);
        }

        participants[msg.sender].claimable_amount = participants[msg.sender].claimable_amount.add(claimableAmount);
        participants[msg.sender].token1_amount = participants[msg.sender].token1_amount.add(token1Amount);
        participants[msg.sender].token2_amount = participants[msg.sender].token2_amount.add(token2Amount);

        presale_current_claimable_amount = presale_current_claimable_amount.add(claimableAmount);

        emit PresaleUpdate(presale_current_claimable_amount, getParticipantsAmount());
    }

    function claim() external whenNotPaused whenClaimIsAvailable {
        require(participants[msg.sender].claimable_amount > 0, "WormRound1Presale: nothing to claim");
        require(IBEP20(claimable_token).balanceOf(address(this)) >= participants[msg.sender].claimable_amount, "WormRound1Presale: insufficient balance");
        require(IBEP20(claimable_token).transfer(msg.sender, participants[msg.sender].claimable_amount), "WormRound1Presale: transfer failed");

        uint256 claimedAmount = participants[msg.sender].claimable_amount;
        participants[msg.sender].claimable_amount = 0;
        participants[msg.sender].claimed = true;

        presale_current_claimed_amount = presale_current_claimed_amount.add(claimedAmount);

        emit PresaleClaimed(presale_current_claimed_amount, msg.sender);
    }

    function refund() external whenNotPaused whenRefundIsAvailable {
        require(!participants[msg.sender].claimed, "WormRound1Presale: token is claimed");
        require(participants[msg.sender].token1_amount > 0, "WormRound1Presale: token1 nothing to refund");
        require(participants[msg.sender].token2_amount > 0, "WormRound1Presale: token2 nothing to refund");

        uint256 amount1 = participants[msg.sender].token1_amount;
        uint256 amount2 = participants[msg.sender].token2_amount;

        participants[msg.sender].token1_amount = 0;
        participants[msg.sender].token2_amount = 0;
        participants[msg.sender].claimable_amount = 0;

        IBEP20(token1_address).transfer(msg.sender, amount1);
        IBEP20(token2_address).transfer(msg.sender, amount2);
    }

    // --==[ Getters ]==--
    function getParticipantsAmount() public view returns (uint256) {
        return participant_addresses.length;
    }

    function getPresaleInfo() public view returns (
        address token1,
        address token2,
        uint256 rawRequiredToken1Amount,
        uint256 rawRequiredToken2Amount,
        uint256 token1Decimals,
        uint256 token2Decimals,
        address claimToken,
        uint256 maxClaimAmount,
        uint256 currentClaimableAmount,
        uint256 currentClaimedAmount,
        uint256 totalParticipantsCount,
        bool contractPaused,
        bool claimAvailable,
        bool refundAvailable
    ) {
        token1 = token1_address;
        token2 = token2_address;
        rawRequiredToken1Amount = raw_required_token1_amount;
        rawRequiredToken2Amount = raw_required_token2_amount;
        token1Decimals = IBEP20(token1_address).decimals();
        token2Decimals = IBEP20(token2_address).decimals();
        claimToken = claimable_token;
        maxClaimAmount = presale_max_claim_amount;
        currentClaimableAmount = presale_current_claimable_amount;
        currentClaimedAmount = presale_current_claimed_amount;
        totalParticipantsCount = getParticipantsAmount();
        contractPaused = paused();
        claimAvailable = claimIsAvailable;
        refundAvailable = refundIsAvailable;
    }

    function getParticipantInfo() public view returns (
        uint256 token1Amount,
        uint256 token2Amount,
        uint256 claimableAmount,
        bool claimed
    ) {
        return getSpecifiedParticipantInfo(msg.sender);
    }

    function getSpecifiedParticipantInfo(address participant) public view returns (
        uint256 token1Amount,
        uint256 token2Amount,
        uint256 claimableAmount,
        bool claimed
    ) {
        token1Amount = participants[participant].token1_amount;
        token2Amount = participants[participant].token2_amount;
        claimableAmount = participants[participant].claimable_amount;
        claimed = participants[participant].claimed;
    }

    // --==[ Pausable ]==--
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // --==[ Unlock ]==--
    bool private claimIsAvailable = false;
    modifier whenClaimIsAvailable {
        require(claimIsAvailable, "Error: Claim is not available");
        _;
    }

    function setClaimIsAvailable(bool _value) external onlyOwner {
        claimIsAvailable = _value;
    }

    bool private refundIsAvailable = false;
    modifier whenRefundIsAvailable {
        require(refundIsAvailable, "Error: Refund is not available");
        _;
    }

    function setRefundIsAvailable(bool _value) external onlyOwner {
        refundIsAvailable = _value;
    }

    // --==[ Helpers ]==--
    function claimableTokensForToken1(uint256 token1Amount) public view returns (uint256) {
        return normalise(token1Amount, token1_address, claimable_token).div(raw_required_token1_amount);
    }

    function claimableTokensForToken2(uint256 token2Amount) public view returns (uint256) {
        return normalise(token2Amount, token1_address, claimable_token).div(raw_required_token2_amount);
    }

    function normalise(uint256 amount, address fromToken, address toToken) public view returns (uint256) {
        uint256 decimals1 = pow(10, IBEP20(fromToken).decimals());
        uint256 decimals2 = pow(10, IBEP20(toToken).decimals());

        if (decimals1 == 0) {
            decimals1 = 18;
        }

        if (decimals2 == 0) {
            decimals2 = 18;
        }

        if (decimals1 > decimals2) {
            uint256 diff = decimals1 - decimals2;
            uint256 denominator = pow(10, diff);
            return amount.div(denominator);
        } else if (decimals1 < decimals2) {
            uint256 diff = decimals2 - decimals1;
            uint256 multiplier = 10 ** diff;
            return amount.mul(multiplier);
        } else {
            // decimals1 == decimals2
            return amount;
        }
    }

    function minRequiredToken1Amount() public view returns (uint256) {
        return tokensFrom(raw_required_token1_amount, token1_address);
    }

    function minRequiredToken2Amount() public view returns (uint256) {
        return tokensFrom(raw_required_token2_amount, token2_address);
    }

    function tokensFrom(uint256 amount, address token_address) public view returns (uint256) {
        uint256 decimals = IBEP20(token_address).decimals();
        return amount * pow(10, decimals);
    }

    function pow(uint256 base, uint256 power) internal pure returns (uint256) {
        return base ** power;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Context.sol";
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
contract Ownable is Context {
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
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
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
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

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
     * // solhint-disable-next-line
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects\
     * -interactions-pattern[checks-effects-interactions pattern].
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
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html\
     * ?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
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
    function functionCall(address target, bytes memory data, string memory errorMessage)
    internal returns (bytes memory)
    {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage)
    internal returns (bytes memory)
    {
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
    function functionStaticCall(address target, bytes memory data)
    internal view returns (bytes memory)
    {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage)
    internal view returns (bytes memory)
    {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage)
    private pure returns(bytes memory)
    {
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
pragma solidity 0.6.12;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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
pragma solidity 0.6.12;

import "../libs/Context.sol";

abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        // silence state mutability warning without generating bytecode -
        // see https://github.com/ethereum/solidity/issues/2691
        this;
        return msg.data;
    }
}

