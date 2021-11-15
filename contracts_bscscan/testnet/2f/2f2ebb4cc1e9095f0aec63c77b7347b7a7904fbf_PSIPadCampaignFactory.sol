// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import './PSIPadCampaign.sol';
import "./interfaces/IFeeAggregator.sol";
import './interfaces/IPSIPadCampaignFactory.sol';

contract PSIPadCampaignFactory is IPSIPadCampaignFactory, Initializable, OwnableUpgradeable {
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public override default_factory;
    address public override default_router;
    address public override fee_aggregator;

    address public override stable_coin; // WETH or WBNB
    uint256 public override stable_coin_fee; // out of 10000
    uint256 public override token_fee; // out of 10000
    
    /**
     * @notice all campaigns
     */
    address[] public campaigns;

    /**
     * @notice campaign ID's for a user
     */
    mapping(address => uint256[]) public userCampaigns;

    modifier isOwner(uint256 campaignId) {
        require(campaigns.length > campaignId, "PSIPadCampaignFactory: CAMPAIGN_DOES_NOT_EXIST");
        require(PSIPadCampaign(campaigns[campaignId]).owner() == msg.sender, "PSIPadCampaignFactory: UNAUTHORIZED");
        _;
    }

    function initialize(
        address _default_factory,
        address _default_router,
        address _fee_aggregator,
        address _stable_coin,
        uint256 _stable_coin_fee,
        uint256 _token_fee
    ) external initializer {
        super.__Ownable_init();
        default_factory = _default_factory;
        default_router = _default_router;
        fee_aggregator = _fee_aggregator;
        stable_coin = _stable_coin;
        stable_coin_fee = _stable_coin_fee;
        token_fee = _token_fee;
    }

    function setDefaultFactory(address _default_factory) external override onlyOwner {
        default_factory = _default_factory;
    }
    function setDefaultRouter(address _default_router) external override onlyOwner {
        default_router = _default_router;
    }
    function setFeeAggregator(address _fee_aggregator) external override onlyOwner {
        fee_aggregator = _fee_aggregator;
    }
    function setStableCoin(address _stable_coin) external override onlyOwner {
        stable_coin = _stable_coin;
    }
    function setStableCoinFee(uint256 _stable_coin_fee) external override onlyOwner {
        stable_coin_fee = _stable_coin_fee;
    }
    function setTokenFee(uint256 _token_fee) external override onlyOwner {
        token_fee = _token_fee;
    }

    function getUserCampaigns(address user) external override view returns(uint256[] memory) {
        return userCampaigns[user];
    }

    /**
     * @notice Start a new campaign using
     * @dev 1 ETH = 1 XYZ (pool_rate = 1e18) <=> 1 ETH = 10 XYZ (pool_rate = 1e19) <=> XYZ (decimals = 18)
     */
     function createCampaign(
        IPSIPadCampaign.CampaignData calldata _data,
        address _token,
        uint256 _tokenFeePercentage
    ) external override returns (address campaign_address) {
        return createCampaignWithOwner(_data, msg.sender, _token, _tokenFeePercentage);
    }
    function createCampaignWithOwner(
        IPSIPadCampaign.CampaignData calldata _data,
        address _owner,
        address _token,
        uint256 _tokenFeePercentage
    ) public override returns (address campaign_address) {
        require(_data.softCap < _data.hardCap, "PSIPadLockFactory: SOFTCAP_HIGHER_THEN_HARDCAP" );
        require(_data.start_date < _data.end_date, "PSIPadLockFactory: STARTDATE_HIGHER_THEN_ENDDATE" );
        require(block.timestamp < _data.end_date, "PSIPadLockFactory: ENDDATE_HIGHER_THEN_CURRENTDATE");
        require(_data.min_allowed < _data.hardCap, "PSIPadLockFactory: MINIMUM_ALLOWED_HIGHER_THEN_HARDCAP" );
        require(_data.rate != 0, "PSIPadLockFactory: RATE_IS_ZERO");
        require(_data.liquidity_rate >= 0 && _data.liquidity_rate <= 10000, 
            "PSIPadLockFactory: LIQUIDITY_RATE_0_10000");
        
        bytes memory bytecode = type(PSIPadCampaign).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_token, _owner));
        assembly {
            campaign_address := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        if (token_fee > 0) IFeeAggregator(fee_aggregator).addFeeToken(_token);

        (uint256 campaignTokens, uint256 feeTokens) = calculateTokens(_data);
        PSIPadCampaign(campaign_address).initialize(
            _data,
            _token,
            _owner,
            default_factory,
            default_router,
            stable_coin_fee,
            campaignTokens,
            feeTokens
        );

        campaigns.push(campaign_address);
        userCampaigns[_owner].push(campaigns.length -1);

        transferToCampaign(
            _data,
            _token,
            campaign_address,
            _tokenFeePercentage
        );

        require(IERC20Upgradeable(_token).balanceOf(campaign_address) >= campaignTokens.add(feeTokens), 
            "PSIPadLockFactory: CAMPAIGN_TOKEN_AMOUNT_TO_LOW");

        emit CampaignAdded(campaign_address, _token, _owner);
        
        return campaign_address;
    }
    function transferToCampaign(
        IPSIPadCampaign.CampaignData calldata _data,
        address _token,
        address _campaign_address,
        uint256 _tokenFeePercentage
    ) internal {
        uint256 tokenAmount = tokensNeeded(_data, _tokenFeePercentage);
        IERC20Upgradeable(_token).safeTransferFrom(msg.sender, _campaign_address, tokenAmount);
    }

    /**
     * @notice calculates how many tokens are needed to start an campaign
     */
    function tokensNeeded(
        IPSIPadCampaign.CampaignData calldata _data,
        uint256 _tokenFeePercentage
    ) public override view returns (uint256) {
        (uint256 campaignTokens, uint256 feeTokens) = calculateTokens(_data);
        uint256 totalTokens = campaignTokens.add(feeTokens);
        // add the token fee transfer percentage if there is any
        return totalTokens.add((totalTokens.mul(_tokenFeePercentage)).div(1e4));
    }
    function calculateTokens(
        IPSIPadCampaign.CampaignData calldata _data
    ) internal view returns (uint256 campaignTokens, uint256 feeTokens) {
        campaignTokens = 
            (_data.hardCap.mul(_data.rate).div(1e18)).add(
                (_data.hardCap.mul(_data.liquidity_rate))
                    .mul(_data.pool_rate).div(1e22)); // pool rate 10000 x 1e18

        feeTokens = (campaignTokens.mul(token_fee)).div(1e4);
    }

    /**
     * @notice Add liqudity to an exchange and burn the remaining tokens, 
     * can only be executed when the campaign completes
     */
    function lock(uint256 campaignId) external override isOwner(campaignId) {
        address campaign = campaigns[campaignId];
        PSIPadCampaign(campaign).lock();
        emit CampaignLocked(campaign, PSIPadCampaign(campaign).token(), PSIPadCampaign(campaign).collected());
    }
    /**
     * @notice allows the owner to unlock the LP tokens and any leftover tokens after the lock has ended
     */
    function unlock(uint256 campaignId) external override isOwner(campaignId) {
        address campaign = campaigns[campaignId];
        PSIPadCampaign(campaign).unlock();
        emit CampaignUnlocked(campaign, PSIPadCampaign(campaign).token());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

pragma solidity ^0.8.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./interfaces/IPSIPadCampaign.sol";
import "./interfaces/IPSIPadCampaignFactory.sol";
import "./interfaces/IFeeAggregator.sol";
import "./interfaces/token/IBEP20.sol";
import "./interfaces/token/IWETH.sol";
import "./interfaces/exchange/IPSIPadFactory.sol";
import "./interfaces/exchange/IPSIPadRouter.sol";

contract PSIPadCampaign is IPSIPadCampaign, Initializable, OwnableUpgradeable {
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address override public immutable psipad_factory;
    
    address override public factory_address;
    address override public router_address;
    uint256 override public stable_coin_fee;
    uint256 override public campaignTokens;
    uint256 override public feeTokens;

    address override public lp_address;
    uint256 override public unlock_date = 0;

    bool override public finalized = false;
    bool override public locked = false;
    bool override public doRefund = false;

    mapping(address => uint) private participants;

    address override public token;
    uint256 override public softCap;
    uint256 override public hardCap;
    uint256 override public start_date;
    uint256 override public end_date;
    uint256 override public rate;
    uint256 override public min_allowed;
    uint256 override public max_allowed;
    uint256 override public pool_rate;
    uint256 override public lock_duration;
    uint256 override public liquidity_rate;
    
    uint256 override public collected;

    constructor() {
        psipad_factory = msg.sender;
    }

    modifier onlyPSIPadFactory() {
        require(msg.sender == psipad_factory, 'PSIPadCampaign: UNAUTHORIZED');
        _;
    }
    
    /**
     * @notice Initialize a new campaign (can only be triggered by the factory contract)
     */
    function initialize(
        CampaignData calldata _data,
        address _token,
        address _owner,
        address _factory_address,
        address _router_address,
        uint256 _stable_coin_fee,
        uint256 _campaignTokens,
        uint256 _feeTokens
    ) external initializer {
        require(msg.sender == psipad_factory, 'PSIPadCampaign: UNAUTHORIZED');

        super.__Ownable_init();
        transferOwnership(_owner);

        token = _token;
        softCap = _data.softCap;
        hardCap = _data.hardCap;
        start_date = _data.start_date;
        end_date = _data.end_date;
        rate = _data.rate;
        min_allowed = _data.min_allowed;
        max_allowed = _data.max_allowed;
        pool_rate = _data.pool_rate;
        lock_duration = _data.lock_duration;
        liquidity_rate = _data.liquidity_rate;

        factory_address = _factory_address;
        router_address = _router_address;
        stable_coin_fee = _stable_coin_fee;
        campaignTokens = _campaignTokens;
        feeTokens = _feeTokens;

        emit Initialized(_owner);
    }

    /**
     * @notice allows an participant to buy tokens (they can be claimed after the campaign succeeds)
     */
    function buyTokens() external override payable {
        require(isLive(), 'PSIPadCampaign: CAMPAIGN_NOT_LIVE');
        require(msg.value >= min_allowed, 'PSIPadCampaign: BELOW_MIN_AMOUNT');
        require(getGivenAmount(msg.sender).add(msg.value) <= max_allowed, 'PSIPadCampaign: ABOVE_MAX_AMOUNT');
        require((msg.value <= getRemaining()), 'PSIPadCampaign: CONTRACT_INSUFFICIENT_TOKENS');

        collected = (collected).add(msg.value);

        // finalize the campaign when hardcap is reached or minimum deposit is not possible anymore
        if(collected >= hardCap || (hardCap - collected) < min_allowed) finalized = true;
        participants[msg.sender] = participants[msg.sender].add(msg.value);

        emit TokensBought(msg.sender, msg.value);
    }

    /**
     * @notice Add liqudity to an exchange and burn the remaining tokens, 
     * can only be executed when the campaign completes
     */
    function lock() external override onlyPSIPadFactory {
        require(!locked, 'PSIPadCampaign: LIQUIDITY_ALREADY_LOCKED');
        require(block.timestamp >= start_date, 'PSIPadCampaign: CAMPAIGN_NOT_STARTED');
        require(!isLive(), 'PSIPadCampaign: CAMPAIGN_STILL_LIVE');
        require(!failed(), "PSIPadCampaign: CAMPAIGN_FAILED");

        (uint256 tokenFee, uint256 stableFee) = calculateFees();
        addLiquidity(stableFee);

        if (!doRefund) {
            locked = true;
            unlock_date = (block.timestamp).add(lock_duration);

            transferFees(tokenFee, stableFee);

            emit CampaignLocked(collected);
        }
    }
    function calculateFees() internal view returns (uint256 tokenFee, uint256 stableFee) {
        if (feeTokens > 0) {
            uint256 collectedPercentage = (collected.mul(1e18)).div(hardCap);
            tokenFee = (feeTokens.mul(collectedPercentage)).div(1e18);
        }

        if (stable_coin_fee > 0) {
            stableFee = (collected.mul(stable_coin_fee)).div(1e4);
        }
    }
    function transferFees(uint256 tokenFee, uint256 stableFee) internal {
        address fee_aggregator = IPSIPadCampaignFactory(psipad_factory).fee_aggregator();

        if (feeTokens > 0) {
            IERC20Upgradeable(token).safeTransfer(fee_aggregator, tokenFee);
            IFeeAggregator(fee_aggregator).addTokenFee(token, tokenFee);
        }

        if (stable_coin_fee > 0) {
            address stable_coin = IPSIPadCampaignFactory(psipad_factory).stable_coin();
            IWETH(stable_coin).deposit{ value: stableFee }();
            IERC20Upgradeable(stable_coin).safeTransfer(fee_aggregator, stableFee);
            IFeeAggregator(fee_aggregator).addTokenFee(stable_coin, stableFee);
        }
    }
    function addLiquidity(uint256 stableFee) internal {
        lp_address = IPSIPadFactory(factory_address)
            .getPair(token, IPSIPadCampaignFactory(psipad_factory).stable_coin());
        
        if (lp_address == address(0) || IBEP20(lp_address).totalSupply() <= 0) {
            uint256 finalCollected = collected;
            if (liquidity_rate + stable_coin_fee > 10000) finalCollected -= stableFee;
            uint256 stableLiquidity = finalCollected.mul(liquidity_rate).div(10000);

            if (stableLiquidity > 0) {
                uint256 tokenLiquidity = (stableLiquidity.mul(pool_rate)).div(1e18);
                IBEP20(token).approve(router_address, tokenLiquidity);
                IPSIPadRouter(router_address).addLiquidityETH{value : stableLiquidity} (
                    address(token),
                    tokenLiquidity,
                    0,
                    0,
                    address(this),
                    block.timestamp + 1000
                );
                
                if (lp_address == address(0)) {
                    lp_address = IPSIPadFactory(factory_address)
                        .getPair(token, IPSIPadCampaignFactory(psipad_factory).stable_coin());
                    require(lp_address != address(0), "PSIPadCampaign: lp address not set");
                }
            }

            payable(owner()).transfer(collected.sub(stableFee).sub(stableLiquidity));
        } else {
            doRefund = true;
        }
    }
    /**
     * @notice Emergency set lp address when funds are f.e. moved. (only possible when tokens are unlocked)
     */
    function setLPAddress(address _lp_address) external override onlyOwner {
        require(locked && !failed(), 'PSIPadCampaign: LIQUIDITY_NOT_LOCKED');
        require(block.timestamp >= unlock_date, "PSIPadCampaign: TOKENS_ARE_LOCKED");
        lp_address = _lp_address;
    }
    /**
     * @notice allows the owner to unlock the LP tokens and any leftover tokens after the lock has ended
     */
    function unlock() external override onlyPSIPadFactory {
        require(locked && !failed(), 'PSIPadCampaign: LIQUIDITY_NOT_LOCKED');
        require(block.timestamp >= unlock_date, "PSIPadCampaign: TOKENS_ARE_LOCKED");
        IERC20Upgradeable(lp_address).safeTransfer(owner(), IBEP20(lp_address).balanceOf(address(this)));
        IERC20Upgradeable(token).safeTransfer(owner(), IBEP20(token).balanceOf(address(this)));
        emit CampaignUnlocked();
    }

    /**
     * @notice Allow participants to withdraw tokens when campaign succeeds
     */
    function withdrawTokens() external override returns (uint256){
        require(locked, 'PSIPadCampaign: LIQUIDITY_NOT_ADDED');
        require(!failed(), 'PSIPadCampaign: CAMPAIGN_FAILED');
        require(participants[msg.sender] > 0, "PSIPadCampaign: NO_PARTICIPANT");
        uint256 amount = calculateAmount(participants[msg.sender]);
        IERC20Upgradeable(token).safeTransfer(msg.sender, amount);
        participants[msg.sender] = 0;
        return amount;
    }
    /**
     * @notice Allow participants to withdraw funds when campaign fails
     */
    function withdrawFunds() external override {
        require(failed(), "PSIPadCampaign: CAMPAIGN_NOT_FAILED");

        if (msg.sender == owner() && IBEP20(token).balanceOf(address(this)) > 0) {
            IERC20Upgradeable(token).safeTransfer(owner(), IBEP20(token).balanceOf(address(this)));
        }

        if (participants[msg.sender] > 0) {
            uint256 withdrawAmount = participants[msg.sender];
            participants[msg.sender] = 0;
            payable(msg.sender).transfer(withdrawAmount);
        }
    }  

    /**
     * @notice Check whether the campaign is still live
     */
    function isLive() public override view returns(bool) {
        if ((block.timestamp < start_date)) return false;
        if ((block.timestamp >= end_date)) return false;
        if (finalized) return false;
        return true;
    }
    /**
     * @notice Check whether the campaign failed
     */
    function failed() public override view returns(bool){
        return ((block.timestamp >= end_date) && softCap > collected) || doRefund;
    }

    /**
     * @notice Returns amount in XYZ
     */
    function calculateAmount(uint256 _amount) public override view returns(uint256){
        return (_amount.mul(rate)).div(1e18);
    }
    /**
     * @notice Get remaining tokens not sold
     */
    function getRemaining() public override view returns (uint256){
        return (hardCap).sub(collected);
    }
    /**
     * Get an participant's contribution
     */
    function getGivenAmount(address _address) public override view returns (uint256){
        return participants[_address];
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

interface IFeeAggregator {
    function addFeeToken(address token) external;
    function addTokenFee(address token, uint256 fee) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./IPSIPadCampaign.sol";

interface IPSIPadCampaignFactory {
    function default_factory() external view returns(address);
    function default_router() external view returns(address);
    function fee_aggregator() external view returns(address);

    function stable_coin() external  view returns(address);
    function stable_coin_fee() external view returns(uint256);
    function token_fee() external view returns(uint256);

    function setDefaultFactory(address _default_factory) external;
    function setDefaultRouter(address _default_router) external;
    function setFeeAggregator(address _fee_aggregator) external;
    function setStableCoin(address _stable_coin) external;
    function setStableCoinFee(uint256 _stable_coin_fee) external;
    function setTokenFee(uint256 _token_fee) external;

    event CampaignAdded(address indexed campaign, address indexed token, address indexed owner);
    event CampaignLocked(address indexed campaign, address indexed token, uint256 indexed collected);
    event CampaignUnlocked(address indexed campaign, address indexed token);

    function getUserCampaigns(address user) external view returns(uint256[] memory);

    /**
     * @notice Start a new campaign using
     * @dev 1 ETH = 1 XYZ (_pool_rate = 1e18) <=> 1 ETH = 10 XYZ (_pool_rate = 1e19) <=> XYZ (decimals = 18)
     */
     function createCampaign(
        IPSIPadCampaign.CampaignData calldata _data,
        address _token,
        uint256 _tokenFeePercentage
    ) external returns (address campaign_address);
    function createCampaignWithOwner(
        IPSIPadCampaign.CampaignData calldata _data,
        address _owner,
        address _token,
        uint256 _tokenFeePercentage
    ) external returns (address campaign_address);

    /**
     * @notice calculates how many tokens are needed to start an campaign
     */
    function tokensNeeded(
        IPSIPadCampaign.CampaignData calldata _data,
        uint256 _tokenFeePercentage
    ) external view returns (uint256 _tokensNeeded);

    /**
     * @notice Add liqudity to an exchange and burn the remaining tokens, 
     * can only be executed when the campaign completes
     */
    function lock(uint256 campaignId) external;
    /**
     * @notice allows the owner to unlock the LP tokens and any leftover tokens after the lock has ended
     */
    function unlock(uint256 campaignId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IPSIPadCampaign {
    struct CampaignData {
        uint256 softCap;
        uint256 hardCap;
        uint256 start_date;
        uint256 end_date;
        uint256 rate;
        uint256 min_allowed;
        uint256 max_allowed;
        uint256 pool_rate;
        uint256 lock_duration;
        uint256 liquidity_rate;
    }

    function psipad_factory() external view returns(address);

    function factory_address() external view returns(address);
    function router_address() external view returns(address);
    function stable_coin_fee() external view returns(uint256);
    function campaignTokens() external view returns(uint256);
    function feeTokens() external view returns(uint256);

    function lp_address() external view returns(address);
    function unlock_date() external view returns(uint256);

    function finalized() external view returns(bool);
    function locked() external view returns(bool);
    function doRefund() external view returns(bool);

    function token() external view returns(address);
    function softCap() external view returns(uint256);
    function hardCap() external view returns(uint256);
    function start_date() external view returns(uint256);
    function end_date() external view returns(uint256);
    function rate() external view returns(uint256);
    function min_allowed() external view returns(uint256);
    function max_allowed() external view returns(uint256);
    function pool_rate() external view returns(uint256);
    function lock_duration() external view returns(uint256);
    function liquidity_rate() external view returns(uint256);
    function collected() external view returns(uint256);

    event Initialized(address indexed owner);
    event TokensBought(address indexed user, uint256 value);
    event CampaignLocked(uint256 collected);
    event CampaignUnlocked();

    /**
     * @notice allows an participant to buy tokens (they can be claimed after the campaign succeeds)
     */
    function buyTokens() external payable;

    /**
     * @notice Add liqudity to an exchange and burn the remaining tokens, 
     * can only be executed when the campaign completes
     */
    function lock() external;
    /**
     * @notice Emergency set lp address when funds are f.e. moved. (only possible when tokens are unlocked)
     */
    function setLPAddress(address _lp_address) external;
    /**
     * @notice allows the owner to unlock the LP tokens and any leftover tokens after the lock has ended
     */
    function unlock() external;
    
    /**
     * @notice Allow participants to withdraw tokens when campaign succeeds
     */
    function withdrawTokens() external returns (uint256);
    /**
     * @notice Allow participants to withdraw funds when campaign fails
     */
    function withdrawFunds() external;

    /**
     * @notice Check whether the campaign is still live
     */
    function isLive() external view returns(bool);
    /**
     * @notice Check whether the campaign failed
     */
    function failed() external view returns(bool);

    /**
     * @notice Returns amount in XYZ
     */
    function calculateAmount(uint256 _amount) external view returns(uint256);
    /**
     * @notice Get remaining tokens not sold
     */
    function getRemaining() external view returns (uint256);
    /**
     * Get an participants contribution
     */
    function getGivenAmount(address _address) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

interface IBEP20 is IERC20MetadataUpgradeable {
    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IWETH {
    function balanceOf(address account) external view returns (uint256);
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IPSIPadFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IPSIPadRouter {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

