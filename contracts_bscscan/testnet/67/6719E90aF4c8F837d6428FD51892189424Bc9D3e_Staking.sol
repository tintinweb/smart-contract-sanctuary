// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/IAdmin.sol";

/**
 * @title Staking.
 * @dev contract for staking tokens.
 *
 */
contract Staking is IStaking {
    using SafeERC20 for IERC20;

    /**
     * EBSC required for different tiers
     */
    bytes32 public constant OPERATOR = keccak256("OPERATOR");

    uint64 constant PCT_BASE = 1 ether;
    uint64 constant ORACLE_MUL = 1e10;
    uint256 constant STARTER_TIER = 2e5 gwei;
    uint256 constant INVESTOR_TIER = 6e5 gwei;
    uint256 constant STRATEGIST_TIER = 25e5 gwei;
    uint256 constant EVANGELIST_TIER = 7e6 gwei;
    uint256 constant EVANGELIST_PRO_TIER = 3e7 gwei;

    uint256 constant FIRST = 2592e3;
    uint256 constant SECOND = 5184e3;
    uint256 constant THIRD = 7776e3;

    IERC20 public lpToken;
    IAdmin public admin;

    mapping(LockLvl => mapping(Tiers => uint256)) public allocation;
    mapping(address => UserState) public override stateOfUser;

    constructor(address _token, address _admin) {
        lpToken = IERC20(_token);
        admin = IAdmin(_admin);
    }

    modifier onlyInstances() {
        require(admin.tokenSalesM(msg.sender), "Sender is not instance");
        _;
    }
    modifier validation(address _address) {
        require(_address != address(0), "Staking: zero address");
        _;
    }
    modifier onlyOperator() {
        require(
            admin.hasRole(OPERATOR, msg.sender),
            "Staking: sender is not an operator"
        );
        _;
    }

    function stakedAmountOf(address _address)
        external
        view
        override
        returns (uint256)
    {
        return stateOfUser[_address].amount;
    }

    function setAdmin(address _address)
        external
        validation(_address)
        onlyOperator
    {
        admin = IAdmin(_address);
    }

    function setToken(address _address)
        external
        validation(_address)
        onlyOperator
    {
        lpToken = IERC20(_address);
    }

    function getTierOf(address _address)
        external
        view
        override
        returns (Tiers)
    {
        return _getHighestTier(_address);
    }

    function setTierTo(address _address, Tiers _tier) 
        external 
        override
        onlyOperator {
        stateOfUser[_address].giftTier = _tier;
    }

    function unsetTierOf(address _address)
        external 
        override 
        onlyOperator {
        stateOfUser[_address].giftTier = Tiers.None;
    }  

    function getAllocationOf(address _address) external view override returns(uint256) {
        UserState storage state = stateOfUser[_address];

        return allocation[state.lock][_getHighestTier(_address)];
    } 

    function setPoolsEndTime(address _address, uint256 _time)
        external
        override
        onlyInstances
    {
        if (stateOfUser[_address].lockTime < _time) {
            stateOfUser[_address].lockTime = _time;
        }
    }

    function stake(LockLvl _level, uint256 _amount) external {
        require(
            _amount > 0,
            "Staking: deposited amount must be greater than 0"
        );
        UserState storage s = stateOfUser[msg.sender];
        if (s.amount != 0) {
            require(uint8(_level) >= uint8(s.lock) || _canUnstake(), "Staking: level < user level");
        }
        s.amount = s.amount + _amount;
        uint256 sec = _secondByLevel(_level);
        s.lock = _level;
        s.lockTime = block.timestamp + sec;
        lpToken.safeTransferFrom(msg.sender, address(this), _amount);
    }
    
    function unstake(uint256 _amount) external override {
        require(_canUnstake(), 'Staking: wait to be able unstake');
        uint256 amount = _amount > 0 ? _amount : stateOfUser[msg.sender].amount;
        _withdraw(amount);
    }

    function _secondByLevel(LockLvl _level) internal pure returns (uint256) {
        if (_level == LockLvl.FIRST) return FIRST;
        if (_level == LockLvl.SECOND) return SECOND;
        if (_level == LockLvl.THIRD) return THIRD;
        return 0;
    }
    //level => Tiers
    function setAllocations(uint256[][4] memory _allocations)
        external
        onlyOperator
    {
        for (uint8 i = 0; i < uint8(_allocations.length); i++) {
            for (uint8 j = 0; j < uint8(_allocations[i].length); j++) {
                require(_allocations[i][j] > 0, "Staking: price must be greater than 0");
                allocation[LockLvl(i)][Tiers(j + 1)] = _allocations[i][j];
            }
        }
    }
    //TODO: write tests
    function changeAllocations(LockLvl _level, Tiers _tier, uint256 _allocation) external onlyOperator {
        require(_allocation > 0, "Staking: price must be greater than 0");
        allocation[_level][_tier] = _allocation;
    }

    function getUserState(address _address) external override view returns(Tiers, LockLvl, uint256, uint256) {
        return (
            _getHighestTier(_address),
            stateOfUser[_address].lock,
            stateOfUser[_address].amount,
            stateOfUser[_address].lockTime
        );
    }

    function _getHighestTier(address _address) internal view returns(Tiers) {
        Tiers _tier = _tierByAmount(stateOfUser[_address].amount, stateOfUser[_address].lock);
        return _tier > stateOfUser[_address].giftTier ? _tier : stateOfUser[_address].giftTier;
    }
 
    function  _canUnstake() internal view returns(bool) {
       return block.timestamp > stateOfUser[msg.sender].lockTime;
    }

    function _tierByAmount(uint256 _amount, LockLvl _level)
        internal
        pure
        returns (Tiers)
    {
        if (_amount >= EVANGELIST_PRO_TIER && _level == LockLvl.THIRD) {
            return Tiers.EvangelistPro;
        } else if (_amount >= EVANGELIST_TIER) {
            return Tiers.Evangelist;
        } else if (_amount >= STRATEGIST_TIER) {
            return Tiers.Strategist;
        } else if (_amount >= INVESTOR_TIER) {
            return Tiers.Investor;
        } else if (_amount >= STARTER_TIER) {
            return Tiers.Starter;
        } else {
            return Tiers.None;
        }
    }

    function _withdraw(uint256 _amount) private {
        stateOfUser[msg.sender].amount -= _amount;
        lpToken.safeTransfer(msg.sender, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

/**
 * @title IStaking.
 * @dev interface for staking
 * with params enum and functions.
 */
interface IStaking {
    /**
     * @dev
     * defines privelege type of address.
     */
    enum Tiers {
        None,
        Starter,
        Investor,
        Strategist,
        Evangelist,
        EvangelistPro
    }

    enum LockLvl {
        NONE,
        FIRST,
        SECOND,
        THIRD
    }

    struct UserState {
        Tiers giftTier;
        LockLvl lock;
        uint256 amount;
        uint256 lockTime;
    }

    function setPoolsEndTime(address, uint256) external;

    function stakedAmountOf(address) external view returns (uint256);

    function setTierTo(address _address, Tiers _tier) external;

    function unsetTierOf(address _address) external;
    
    //function stake(uint256) external;

    function getAllocationOf(address) external returns (uint256);

    function unstake(uint256) external;

    function getUserState(address)
        external
        returns (
            Tiers,
            LockLvl,
            uint256,
            uint256
        );

    function stateOfUser(address)
        external
        returns (
            Tiers,
            LockLvl,
            uint256,
            uint256
        );

    function getTierOf(address) external view returns (Tiers);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./ITokenSale.sol";

/**
 * @title IAdmin.
 * @dev interface of Admin contract
 * which can set addresses for contracts for:
 * airdrop, token sales maintainers, staking.
 * Also Admin can create new pool.
 */
interface IAdmin is IAccessControl {
    function getParams(address)
        external
        view
        returns (ITokenSale.Params memory);

    function airdrop() external returns (address);

    function exchangeOracle() external returns (address);

    function tokenSalesM(address) external returns (bool);

    function blockClaim(address) external returns (bool);

    function tokenSales(uint256) external returns (address);

    function masterTokenSale() external returns (address);

    function stakingContract() external returns (address);

    function setMasterContract(address) external;

    function setAirdrop(address _newAddress) external;

    function setStakingContract(address) external;

    function setOracleContract(address) external;

    function createPool(ITokenSale.Params calldata _params) external;

    function getTokenSales() external view returns (address[] memory);

    function wallet() external view returns (address);

    function addToBlackList(address, address[] memory) external;

    function blacklist(address, address) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
     * bearer except when using {AccessControl-_setupRole}.
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
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

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
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: UNLICENSED

/**
 * @title ITokenSale.
 * @dev interface of ITokenSale
 * params structure and functions.
 */
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;
import "./IStaking.sol";

interface ITokenSale {
    struct Staked {
        uint256 amount;
        uint256 share;
        uint256 claim;
        bool free;
        int8 point;
    }
    enum Epoch {
        Incoming,
        Private,
        Waiting,
        Public,
        Finished
    }

    /**
     * @dev describe initial params for token sale
     * @param totalSupply set total amount of tokens. (Token decimals)
     * @param privateStart set starting time for private sale.
     * @param privateEnd set finish time for private sale.
     * @param publicStart set starting time for public sale.
     * @param privateEnd set finish time for private sale.
     * @param privateTokenPrice set price for private sale per token in $ (18 decimals).
     * @param publicTokenPrice set price for public sale per token in $ (18 decimals).
     * @param publicBuyLimit set limit for tokens per address in $ (18 decimals).
     * @param escrowPercentage set interest rate for depositor. >
     * @param tierPrices set price to calculate maximum value by tier for staking.
     * @param thresholdPublicAmount - should be sold more than that.
     * @param airdrop - amount reserved for airdrop
     */
    struct Params {
        address initial;
        address token;
        uint256 totalSupply; //MUST BE 10**18;
        uint256 privateStart;
        uint256 privateEnd;
        uint256 publicStart;
        uint256 publicEnd;
        uint256 privateTokenPrice; // MUST BE 10**18 in bnb
        uint256 publicTokenPrice; // MUST BE 10**18 in bnb
        uint256 publicBuyLimit; //// MUST BE 10**18 in $
        uint256 escrowPercentage; // Percentage base is 1000
        uint256[2][] escrowReturnMilestones; // Percentage base is 1000
        //in erc decimals
        uint256 thresholdPublicAmount;
        //[timeStamp, pct]
        uint256[2][] vestingPoints; // Percentage base is 1000
        uint256 tokenFeePct; // in tokens
        uint256 valueFeePct; // in 10**18;
    }

    /**
     * @dev initialize implementation logic contracts addresses
     * @param _stakingContract for staking contract.
     * @param _admin for admin contract.
     * @param _priceFeed for price aggregator contract.
     */
    function initialize(
        Params memory,
        address _stakingContract,
        address _admin,
        address _priceFeed
    ) external;

    /**
     * @dev claim to sell tokens in airdrop.
     */
    function claim() external;

    /**
     * @dev get banned list of addresses from participation in sales in this contract.
     */
    function epoch() external returns (Epoch);

    function publicPurchased(address) external returns (uint256);

    function destroy() external;

    //function exchangeRate() external returns (int256);

    //function totalPrivateSold() external returns (uint256);

    //function totalPublicSold() external returns (uint256);

    //function addToBlackList(address[] memory) external;

    function takeLeftovers() external;

    function stakes(address)
        external
        returns (
            uint256,
            uint256,
            uint256,
            bool,
            int8
        );

    function takeLocked() external;

    //function getState()

    event DepositPrivate(address indexed user, uint256 amount);
    event DepositPublic(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount, uint256 change);
    event TransferAirdrop(uint256 amount);
    event TransferLeftovers(uint256 leftovers, uint256 fee, uint256 earned);
}