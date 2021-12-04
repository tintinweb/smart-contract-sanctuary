pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import { IMarket } from "../interface/IMarket.sol";
import { IStakeble } from "../interface/IStakeble.sol";
import { IRewardable } from "../interface/IRewardable.sol";
import { IRewarder } from "../interface/IRewarder.sol";

import { IStrips } from "../interface/IStrips.sol";
import { IAssetOracle } from "../interface/IAssetOracle.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IStripsLpToken } from "../interface/IStripsLpToken.sol";
import { MGetters } from "./Getters.sol";
import { StakingImpl } from "../impl/StakingImpl.sol";
import { SlpFactoryImpl } from "../impl/SlpFactoryImpl.sol";

import { SLPToken } from "../token/SLPToken.sol";
import { SignedBaseMath } from "../lib/SignedBaseMath.sol";
import { StorageMarketLib } from "../lib/StorageMarket.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

//Market contract for particular derivative
//Should implement asset specific methods and calculations
//TODO: set owner STRIPS
contract IrsMarket is
    IMarket,
    IStakeble,
    IRewardable,
    MGetters,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SignedBaseMath for int256;
    using StorageMarketLib for StorageMarketLib.State;

    bytes32 public constant STRIPS_ROLE = keccak256("STRIPS_ROLE");
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    modifier notSuspended() {
        require(m_state.isSuspended == false, "SUSPENDED");
        require(address(m_state.slpToken) != address(0), "SLP_NOT_CREATED");
         _;
    }

    function initialize (
        StorageMarketLib.InitParams memory _params,
        address _sushiRouter,
        address _dao
    ) public initializer
    {
        require(Address.isContract(_sushiRouter), "SUSHI_ROUTER_NOT_A_CONTRACT");
        require(address(_params.stripsProxy) != address(0), "NO_STRIPS_ERROR");
        require(_dao != address(0), "ZERO_DAO");

        __AccessControl_init();
        __ReentrancyGuard_init();

        m_state.dao = _dao;
        m_state.params = _params;
        m_state.sushiRouter = _sushiRouter;

        m_state.createdAt = block.timestamp;

        if (m_state.ratio == 0){
            m_state.ratio = SignedBaseMath.oneDecimal();
        }

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OWNER_ROLE, msg.sender);
        _setupRole(STRIPS_ROLE, address(_params.stripsProxy));
    }

    function isRewardable() external view override returns (bool)
    {
        return true;        
    }

    function changeDao(address _newDao) external onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_newDao != address(0), "ZERO_DAO");
        m_state.dao = _newDao;
    }


    function getStrips() external view override returns (address) {
        return address(m_state.params.stripsProxy);
    }

    function createRewarder(IRewarder.InitParams memory _params) external override onlyRole(OWNER_ROLE)
    {
        require(address(m_state.rewarder) == address(0), "REWARDER_EXIST");

        m_state.rewarder = SlpFactoryImpl._rewarderFactory(_params);

    }

    function getRewarder() external view override returns (address)
    {
        return address(m_state.rewarder);
    }


    function createSLP(IStripsLpToken.TokenParams memory _params) external override onlyRole(OWNER_ROLE) {
        require(address(m_state.slpToken) == address(0), "LP_TOKEN_EXIST");

        
        m_state.slpToken = SlpFactoryImpl._slpFactory(_params,
                                                    "SLP Token",
                                                    "SLP");
    }

    function approveStrips(IERC20 _token, int256 _amount) external override onlyRole(STRIPS_ROLE) {
        m_state.approveStrips(_token, _amount);
    }

    function openPosition(
        bool isLong,
        int256 notional
    ) external override nonReentrant notSuspended onlyRole(STRIPS_ROLE) returns (int256){
        require(notional > 0, "NOTIONAL_LT_0");
        
        if (isLong == true){
            m_state.totalLongs += notional;
            m_state._updateRatio(notional, 0);
        }else{
            m_state.totalShorts += notional;
            m_state._updateRatio(0, notional);
        }

        return m_state.currentPrice();
    }

    function closePosition(
        bool isLong,
        int256 notional
    ) external override nonReentrant notSuspended onlyRole(STRIPS_ROLE) returns (int256){
        require(notional > 0, "NOTIONAL_LT_0");

        //TODO: check for slippage, if it's big then the trader PAY slippage
        if (isLong){
            m_state.totalLongs -= notional;
            require(m_state.totalLongs >= 0, "TOTALLONGS_LT_0");
            
            m_state._updateRatio(0 - notional, 0);
        }else{
            m_state.totalShorts -= notional;
            require(m_state.totalShorts >= 0, "TOTALSHORTS_LT_0");

            m_state._updateRatio(0, 0 - notional);
        }

        return m_state.currentPrice();
    }


    // SHORT: openPrice = initialPrice * (demand / (supply + notional))
    // LONG: openPrice = initialPrice * (demand / (supply + notional))
    // demand = total_longs + stackedLiquidity;
    // supply = total_shorts + stackedLiquidity 
    function priceChange(
        int256 notional,
        bool isLong
    ) public view override returns (int256){
        if (isLong){
            return _priceChangeOnLong(notional);
        }

        return _priceChangeOnShort(notional);
    }

    function _priceChangeOnLong(
        int256 notional
    ) private view returns (int256){

        int256 ratio = m_state._whatIfRatio(notional, 0);

        return m_state.params.initialPrice.muld(ratio);
    }

    function _priceChangeOnShort(
        int256 notional
    ) private view returns (int256){
        int256 ratio = m_state._whatIfRatio(0, notional);

        return m_state.params.initialPrice.muld(ratio);
    }


    /*
    ********************************************************************
    * Stake/Unstake related functions
    ********************************************************************
    */
    function liveTime() external view override returns (uint){
        return block.timestamp - m_state.createdAt;
    }

    function isInsurance() external view override returns (bool){
        return false;
    }

    function totalStaked() external view override returns (int256)
    {
        return m_state.calcStakingLiqudity();
    }

    function getSlpToken() external view override returns (address) {
        return address(m_state.slpToken);
    }

    function getStakingToken() external view override returns (address)
    {
        return address(m_state.params.stakingToken);
    }

    function getTradingToken() external view override returns (address)
    {
        return address(m_state.params.tradingToken);
    }

    function ensureFunds(int256 amount) external override nonReentrant notSuspended onlyRole(STRIPS_ROLE) {
        int256 diff = m_state.calcTradingLiqudity() - amount;
        if (diff >= 0){
            return;
        }

        //diff *= -1;
        StakingImpl._burnPair(m_state.slpToken,
                                amount);
    }

    function stake(int256 amount) external override nonReentrant notSuspended {
        StakingImpl._stake(m_state.slpToken,
                            msg.sender,
                            amount);
    }

    function unstake(int256 amount) external override nonReentrant notSuspended {
        StakingImpl._unstake(m_state.slpToken,
                            msg.sender,
                            amount);
        
    }

    function externalLiquidityChanged() external override nonReentrant onlyRole(STRIPS_ROLE){

    }

    function changeTradingPnl(int256 amount) public override nonReentrant onlyRole(STRIPS_ROLE){
        m_state.slpToken.changeTradingPnl(amount);
    }
    
    function changeStakingPnl(int256 amount) public override nonReentrant onlyRole(STRIPS_ROLE){
        m_state.slpToken.changeStakingPnl(amount);
    }


    /* UTILS */
    function changeSushiRouter(address _router) external override onlyRole(OWNER_ROLE)
    {
        require(Address.isContract(_router), "SUSHI_ROUTER_NOT_A_CONTRACT");

        m_state.sushiRouter = _router;

    }
    function getSushiRouter() external view override returns (address)
    {
        return m_state.sushiRouter;
    }

    function getStrp() external view override returns (address)
    {
        return address(m_state.params.strpToken);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function renounceRole(bytes32 role, address account) public virtual override {
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
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

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IStripsLpToken } from "./IStripsLpToken.sol";
import { IUniswapV2Pair } from "../external/interfaces/IUniswapV2Pair.sol";

interface IMarket {
    function getLongs() external view returns (int256);
    function getShorts() external view returns (int256);

    function priceChange(int256 notional, bool isLong) external view returns (int256);
    function currentPrice() external view returns (int256);
    function oraclePrice() external view returns (int256);
    
    function getAssetOracle() external view returns (address);
    function getPairOracle() external view returns (address);
    function currentOracleIndex() external view returns (uint256);

    function getPrices() external view returns (int256 marketPrice, int256 oraclePrice);    
    function getLiquidity() external view returns (int256);
    function getPartedLiquidity() external view returns (int256 tradingLiquidity, int256 stakingLiquidity);

    function openPosition(
        bool isLong,
        int256 notional
    ) external returns (int256 openPrice);

    function closePosition(
        bool isLong,
        int256 notional
    ) external returns (int256);

    function maxNotional() external view returns (int256);
}

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IStripsLpToken } from "./IStripsLpToken.sol";
import { IStakebleEvents } from "../lib/events/Stakeble.sol";

interface IStakeble is IStakebleEvents {
    event LiquidityChanged(
        address indexed asset,
        address indexed changer,
        string indexed action,
        
        int256 totalLiquidity,
        int256 currentStakedPnl,
        int256 stakerInitialStakedPnl,
        int256 stakerTotalCollateral
    );

    event TokenAdded(
        address indexed asset,
        address indexed token
    );

    event LogStakeChanged(
        address indexed asset,
        address indexed changer,
        bool isStake,
        
        int256 burnedSlp,
        int256 unstakeLp,
        int256 unstakeUsdc,

        int256 lp_fee,
        int256 usdc_fee
    );
    function createSLP(IStripsLpToken.TokenParams memory _params) external;
    function totalStaked() external view returns (int256);
    function isInsurance() external view returns (bool);
    function liveTime() external view returns (uint);

    function getSlpToken() external view returns (address);
    function getStakingToken() external view returns (address);
    function getTradingToken() external view returns (address);
    function getStrips() external view returns (address);

    function ensureFunds(int256 amount) external;
    function stake(int256 amount) external;
    function unstake(int256 amount) external;

    function approveStrips(IERC20 _token, int256 _amount) external;
    function externalLiquidityChanged() external;

    function changeTradingPnl(int256 amount) external;
    function changeStakingPnl(int256 amount) external;

    function isRewardable() external view returns (bool);

    function changeSushiRouter(address _router) external;
    function getSushiRouter() external view returns (address);

    function getStrp() external view returns (address);
}

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IStripsLpToken } from "./IStripsLpToken.sol";
import { IStakebleEvents } from "../lib/events/Stakeble.sol";
import { IRewarder } from "./IRewarder.sol";

interface IRewardable {
    function createRewarder(IRewarder.InitParams memory _params) external;
    function getRewarder() external view returns (address);
}

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IStripsLpToken } from "./IStripsLpToken.sol";
import { IStakebleEvents } from "../lib/events/Stakeble.sol";

interface IRewarder {
    event TradingRewardClaimed(
        address indexed user, 
        int256 amount
    );

    event StakingRewardClaimed(
        address indexed user, 
        int256 amount
    );

    struct InitParams {
        uint256 periodLength;
        uint256 washTime;

        IERC20 slpToken;
        IERC20 strpToken;

        address stripsProxy;
        address dao;
        address admin;

        int256 rewardTotalPerSecTrader;
        int256 rewardTotalPerSecStaker;
    }

    function claimStakingReward(address _staker) external;
    function claimTradingReward(address _trader) external;

    function totalStakerReward(address _staker) external view returns (int256 reward);
    function totalTradeReward(address _trader) external view returns (int256 reward);

    function rewardStaker(address _staker) external;
    function rewardTrader(address _trader, int256 _notional) external;

    function currentTradingReward() external view returns(int256);
    function currentStakingReward() external view returns (int256);
}

pragma solidity ^0.8.0;

import { IMarket } from "./IMarket.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IInsuranceFund } from "./IInsuranceFund.sol";
import { IStripsLpToken } from "./IStripsLpToken.sol";

import { StorageStripsLib } from "../lib/StorageStrips.sol";
import { IStripsEvents } from "../lib/events/Strips.sol";

interface IStrips is IStripsEvents 
{

    /*
        State actions
     */
    enum StateActionType {
        ClaimRewards
    }

    /*request */
    struct ClaimRewardsParams {
        address account;
    }

    struct StateActionArgs {
        StateActionType actionType;
        bytes data;
    }


    /*
        View actions
     */
    enum ViewActionType {
        GetOracles,
        GetMarkets,
        CalcFeeAndSlippage,
        GetPosition,
        CalcClose,
        CalcRewards
    }

    /*request */
    struct CalcRewardsParams {
        address account;
    }
    /*response */
    struct CalcRewardsData {
        address account;
        int256 rewardsTotal;
    }


    /*request */
    struct CalcCloseParams {
        address market;
        address account;
        int256 closeRatio;
    }
    /*response */
    struct CalcCloseData {
        address market;
        int256 minimumMargin;
        int256 pnl;
        int256 marginLeft;
        int256 fee;
        int256 slippage;
        int256 whatIfPrice;
    }

    /*
        request 
        response: PositionParams or revert
    */
    struct GetPositionParams {
        address market;
        address account;
    }


    /*request */
    struct FeeAndSlippageParams {
        address market;
        int256 notional;
        int256 collateral;
        bool isLong;
    }

    /* response */
    struct FeeAndSlippageData{
        address market;
        int256 marketRate;
        int256 oracleRate;
        
        int256 fee;
        int256 whatIfPrice;
        int256 slippage;

        int256 minimumMargin;
        int256 estimatedMargin;
    }


    struct ViewActionArgs {
        ViewActionType actionType;
        bytes data;
    }


    /*
        Admin actions
     */

    enum AdminActionType {
        AddMarket,   
        AddOracle,  
        RemoveOracle,  
        ChangeOracle,
        SetInsurance,
        ChangeRisk
    }

    struct AddMarketParams{
        address market;
    }

    struct AddOracleParams{
        address oracle;
        int256 keeperReward;
    }

    struct RemoveOracleParams{
        address oracle;
    }

    struct ChangeOracleParams{
        address oracle;
        int256 newReward;
    }

    struct SetInsuranceParams{
        address insurance;
    }

    struct ChangeRiskParams{
        StorageStripsLib.RiskParams riskParams;
    }


    struct AdminActionArgs {
        AdminActionType actionType;
        bytes data;
    }



    /*
        Events
     */
    event LogNewMarket(
        address indexed market
    );

    event LogPositionUpdate(
        address indexed account,
        IMarket indexed market,
        PositionParams params
    );

    struct PositionParams {
        // true - for long, false - for short
        bool isLong;
        // is this position closed or not
        bool isActive;
        // is this position liquidated or not
        bool isLiquidated;

        //position size in USDC
        int256 notional;
        //collateral size in USDC
        int256 collateral;
        //initial price for position
        int256 initialPrice;
    }

    struct PositionData {
        //address of the market
        IMarket market;
        // total pnl - real-time profit or loss for this position
        int256 pnl;

        // this pnl is calculated based on whatIfPrice
        int256 pnlWhatIf;
        
        // current margin ratio of the position
        int256 marginRatio;
        PositionParams positionParams;
    }

    struct AssetData {
        bool isInsurance;
        
        address asset;
         // Address of SLP/SIP token
        address slpToken;

        int256 marketPrice;
        int256 oraclePrice;

        int256 maxNotional;
        int256 tvl;
        int256 apy;

        int256 minimumMargin;
    }

    struct StakingData {
         //Market or Insurance address
        address asset; 

        // collateral = slp amount
        uint256 totalStaked;
    }

    /**
     * @notice Struct that keep real-time trading data
     */
    struct TradingInfo {
        //Includes also info about the current market prices, to show on dashboard
        AssetData[] assetData;
        PositionData[] positionData;
    }

    /**
     * @notice Struct that keep real-time staking data
     */
    struct StakingInfo {
        //Includes also info about the current market prices, to show on dashboard
        AssetData[] assetData;
        StakingData[] stakingData;
    }

    /**
     * @notice Struct that keep staking and trading data
     */
    struct AllInfo {
        TradingInfo tradingInfo;
        StakingInfo stakingInfo;
    }

    function open(
        IMarket _market,
        bool isLong,
        int256 collateral,
        int256 leverage,
        int256 slippage
    ) external;

    function close(
        IMarket _market,
        int256 _closeRatio,
        int256 _slippage
    ) external;

    function changeCollateral(
        IMarket _market,
        int256 collateral,
        bool isAdd
    ) external;

    function ping() external;
    function getPositionsCount() external view returns (uint);
    function getPositionsForLiquidation(uint _start, uint _length) external view returns (StorageStripsLib.PositionMeta[] memory);
    function liquidatePosition(IMarket _market, address account) external;
    function payKeeperReward(address keeper) external;

    /*
        Strips getters functions for Trader
     */
    function assetPnl(address _asset) external view returns (int256);
    function getLpOracle() external view returns (address);

}

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

interface IAssetOracle is KeeperCompatibleInterface {
    function getPrice() external view returns (int256);
    function calcOracleAverage(uint256 fromIndex) external view returns (int256);
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IUniswapV2Pair } from "../external/interfaces/IUniswapV2Pair.sol";
import { IStrips } from "../interface/IStrips.sol";

interface IStripsLpToken is IERC20 {
    struct TokenParams {
        address stripsProxy;
        address pairOracle;

        address tradingToken;
        address stakingToken; 

        int256 penaltyPeriod;
        int256 penaltyFee;
    }

    struct ProfitParams{
        int256 unstakeAmountLP;
        int256 unstakeAmountERC20;

        int256 stakingProfit;   
        int256 stakingFee;

        int256 penaltyLeft;
        uint256 totalStaked;

        int256 lpPrice;

        int256 lpProfit;
        int256 usdcLoss;
    }

    function getParams() external view returns (TokenParams memory);
    function getBurnableToken() external view returns (address);
    function getPairPrice() external view returns (int256);
    function checkOwnership() external view returns (address);

    function totalPnl() external view returns (int256 usdcTotal, int256 lpTotal);

    function accumulatePnl() external;
    function saveProfit(address staker) external;
    function mint(address staker, uint256 amount) external;
    function burn(address staker, uint256 amount) external;

    function calcFeeLeft(address staker) external view returns (int256 feeShare, int256 periodLeft);
    function calcProfit(address staker, uint256 amount) external view returns (ProfitParams memory);

    function claimProfit(address staker, uint256 amount) external returns (int256 stakingProfit, int256 tradingProfit);
    function setPenaltyFee(int256 _fee) external;
    function setParams(TokenParams memory _params) external;
    function canUnstake(address staker, uint256 amount) external view;

    function changeTradingPnl(int256 amount) external;
    function changeStakingPnl(int256 amount) external;

}

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IMarket } from "../interface/IMarket.sol";
import { IStripsLpToken } from "../interface/IStripsLpToken.sol";
import { IUniswapV2Pair } from "../external/interfaces/IUniswapV2Pair.sol";

import { MState } from "./State.sol";
import { StorageMarketLib } from "../lib/StorageMarket.sol";
import { SignedBaseMath } from "../lib/SignedBaseMath.sol";
import { StakingImpl } from "../impl/StakingImpl.sol";
import { AssetOracle } from "../oracle/AssetOracle.sol";

abstract contract MGetters is
    IMarket,
    MState
{
    using StorageMarketLib for StorageMarketLib.State;
    using SignedBaseMath for int256;

    function currentPrice() external view override returns (int256) {
        return m_state.currentPrice();
    }

    function oraclePrice() external view override returns (int256) {
        return m_state.oraclePrice();
    }
    
    /**
     * @notice total longs positions notional for this market. 
     * @return in USDC
     */
    function getLongs() external view override returns (int256) 
    {
        return m_state.totalLongs;
    }

    /**
     * @notice total shorts positions notional for this market. 
     * @return in USDC
     */
    function getShorts() external view override returns (int256) {
        return m_state.totalShorts;
    }

    /**
     * @notice using to receive the maximum position size for the current market
     * @return maximum position size (after leverage) in USDC
     */
    function maxNotional() external view override returns (int256) {
        return m_state.maxNotional();
    }


    function getPrices() external view override returns (int256, int256) {
        return m_state.getPrices();
    }

    function getLiquidity() external view override returns (int256) {
        return m_state.getLiquidity();
    }

    function getPartedLiquidity() external view override returns (int256 tradingLiquidity, int256 stakingLiquidity) {
        tradingLiquidity = m_state.calcTradingLiqudity();
        stakingLiquidity = m_state.calcStakingLiqudity();
    }

    function getAssetOracle() external view override returns (address)
    {
        return address(m_state.params.assetOracle);
    }

    function getPairOracle() external view override returns (address)
    {
        return address(m_state.params.pairOracle);
    }

    function currentOracleIndex() external view override returns (uint256) 
    {
        return AssetOracle(address(m_state.params.assetOracle)).lastCumulativeIndex();
    }


}

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IStripsLpToken } from "../interface/IStripsLpToken.sol";
import { IStrips } from "../interface/IStrips.sol";
import { IMarket } from "../interface/IMarket.sol";
import { IStripsLpToken } from "../interface/IStripsLpToken.sol";
import { IStakeble } from "../interface/IStakeble.sol";
import { SignedBaseMath } from "../lib/SignedBaseMath.sol";
import { SLPToken } from "../token/SLPToken.sol";
import { StakebleEvents, IStakebleEvents } from "../lib/events/Stakeble.sol";
import { IRewarder } from "../interface/IRewarder.sol";
import { IRewardable } from "../interface/IRewardable.sol";

import { IUniswapV2Router02 } from "../external/interfaces/IUniswapV2Router02.sol";
import { IUniswapV2Pair } from "../external/interfaces/IUniswapV2Pair.sol";
import { IUniswapV2Factory } from "../external/interfaces/IUniswapV2Factory.sol";


library StakingImpl {
    using SignedBaseMath for int256;

    struct BurnParams{
        IUniswapV2Router02 router;
        IUniswapV2Factory factory;
        IUniswapV2Pair pair;

        address strp;
        address usdc;

        int256 strpReserve;
        int256 usdcReserve;

        int256 liquidity;

        int256 amountIn;  //strp to swap
        int256 amountOutMin; //minimum usdc to receive on swap
    }

    modifier onlyStaker (address staker) {
        require(msg.sender == staker, "STAKER_ONLY");
         _;
    }

    function _stake(
        IStripsLpToken slpToken,
        address staker,
        int256 amount
    ) external onlyStaker(staker) {
        require(amount > 0, "WRONG_AMOUNT");
        slpToken.accumulatePnl();

        //The staker already has stake, need to store current Profit
        if (slpToken.balanceOf(staker) > 0){
            slpToken.saveProfit(staker);
        }

        SafeERC20.safeTransferFrom(IERC20(slpToken.getParams().stakingToken), 
                                    staker, 
                                    address(this), 
                                    uint(amount));

        slpToken.mint(staker, uint(amount));

        if (IStakeble(address(this)).isRewardable()){
            address rewarder = IRewardable(address(this)).getRewarder();
            IRewarder(rewarder).rewardStaker(staker);
        }
    }

  
    function _unstake(
        IStripsLpToken slpToken,
        address staker,
        int256 amount
    ) external onlyStaker(staker) {
        slpToken.canUnstake(staker, uint(amount));

        slpToken.accumulatePnl();

        (int256 stakingProfit,
            int256 tradingProfit) = slpToken.claimProfit(staker, uint(amount));

        require(stakingProfit > 0 && tradingProfit >= 0, "NO_PROFIT");

        if (stakingProfit > 0){
            SafeERC20.safeTransfer(IERC20(slpToken.getParams().stakingToken), 
                                    staker, 
                                    uint(stakingProfit));
        }

        if (tradingProfit > 0){
            int256 diff = int256(IERC20(slpToken.getParams().tradingToken).balanceOf(address(this))) - tradingProfit;
            if (diff < 0){
                /*Burn LP to get USDC*/
                diff *= -1;

                _burnPair(slpToken, diff);
            }
            SafeERC20.safeTransfer(IERC20(slpToken.getParams().tradingToken), 
                                    staker, 
                                    uint(tradingProfit));

        }

        StakebleEvents.logUnstakeData(SLPToken(address(slpToken)).owner(), 
                                                staker, 
                                                amount,
                                                stakingProfit,
                                                tradingProfit);

        if (IStakeble(address(this)).isRewardable()){
            address rewarder = IRewardable(address(this)).getRewarder();
            IRewarder(rewarder).rewardStaker(staker);
        }
    }

    function _burnPair(
        IStripsLpToken slpToken,
        int256 requiredAmount
    ) public {
        //ONLY if we are in Owner context (address(this) == owner), otherwise revert
        slpToken.checkOwnership();

        require(requiredAmount > 0, "WRONG_AMOUNT");
    /*
            Steps for burning LP:
            1. Find reserves
            2. Calc liquidity amount to burn
            3. Burn
            4. Swap STRP to USDC with slippage
            5. Reflect lp and usdc growth
         */

        BurnParams memory params;

        params.strp = IStakeble(address(this)).getStrp();
        params.usdc = slpToken.getParams().tradingToken;
        
        params.router = IUniswapV2Router02(IStakeble(address(this)).getSushiRouter());
        params.factory = IUniswapV2Factory(params.router.factory());
        params.pair = IUniswapV2Pair(params.factory.getPair(
            params.strp,
            params.usdc));
        require(address(params.pair) != address(0), "ZERO_PAIR_CONTRACT");

        (uint112 reserve0,
            uint112 reserve1,) = params.pair.getReserves();

        if (address(params.strp) == params.pair.token0()){
            params.strpReserve = int256(uint(reserve0));
            params.usdcReserve = int256(uint(reserve1));
        }else{
            params.strpReserve = int256(uint(reserve1));
            params.usdcReserve = int256(uint(reserve0));
        }

        /*How much liquidity we need to burn? */
        int256 supply = int256(params.pair.totalSupply());

        /*Just 10% maximum for don't care about the fee */
        params.liquidity = (requiredAmount.muld(supply).divd(params.usdcReserve)).muld(SignedBaseMath.onpointOne());


        /*
            Need to calc balance before burn - as we need to change PNL to differ
         */
        int256 lp_balance = int256(params.pair.balanceOf(address(this)));
        int256 usdc_balance = int256(IERC20(params.usdc).balanceOf(address(this)));

        /*BURN:
            address tokenA,
            address tokenB,
            uint liquidity,
            uint amountAMin,
            uint amountBMin,
            address to,
            uint deadline
         */
        params.pair.approve(address(params.router), uint(params.liquidity));
        params.router.removeLiquidity(
            address(params.usdc), 
            address(params.strp), 
            uint(params.liquidity), 
            uint(requiredAmount),
            0, 
            address(this), 
            block.timestamp + 200);

        /*
            Change reserves
         */
        (reserve0,
            reserve1,) = params.pair.getReserves();

        if (address(params.strp) == params.pair.token0()){
            params.strpReserve = int256(uint(reserve0));
            params.usdcReserve = int256(uint(reserve1));
        }else{
            params.strpReserve = int256(uint(reserve1));
            params.usdcReserve = int256(uint(reserve0));
        }


        /*NOW SWAP */
        params.amountIn = int256(IERC20(params.strp).balanceOf(address(this)));
        require(params.amountIn > 0, "BURN_FAILED_ZERO_STRP");

        IERC20(params.strp).approve(address(params.router), uint(params.amountIn));
        params.amountOutMin = int256(params.router.quote(uint(params.amountIn), uint(params.strpReserve), uint(params.usdcReserve)));

        /*10% slippage */
        params.amountOutMin = params.amountOutMin.muld(SignedBaseMath.ninetyPercent());
        address[] memory path = new address[](2);
        path[0] = params.strp;
        path[1] = params.usdc;

        params.router.swapExactTokensForTokens(
            uint(params.amountIn),
            uint(params.amountOutMin),
            path,
            address(this),
            block.timestamp + 200
        );
        
        /*Calc change in balance */
        int256 lp_diff = int256(params.pair.balanceOf(address(this))) - lp_balance;
        require (lp_diff < 0, "LP_BURN_ERROR");

        int256 usdc_diff = int256(IERC20(params.usdc).balanceOf(address(this))) - usdc_balance;
        require (usdc_diff > 0, "USDC_BURN_ERROR");

        /*Reflect change*/
        slpToken.changeStakingPnl(lp_diff);
        slpToken.changeTradingPnl(usdc_diff);
    }
}



/*
********** The staking PNL distribution explained ****************************

|.........(pnl0)(ts0)|staker1(+sa1).............(pnl1)(ts1)|staker2 (+sa2)...........(pnl2)(ts2)|staker3 (+sa3)........(pnl3)(ts3)|staker2 (-sa21)


pnl(i) - pnl of the market at moment(i)
ts(i) - SLP total Supply at moment (i)
+-sa(i) - staked amount of staker (i) 

When staker2 unstake (-sa21) the formula to calculate the profit:

profit = (pnl2 - pnl1) * sa21/ts2 + (pnl3 - pnl2) * sa21/ts3 = sa21 * [(pnl2 - pnl1)/ts2 + (pnl3 - pnl2)/ts3] 

MOMENT 0:
1. totalCummulativePnl = 0

WHEN STAKER1 STAKE (corner case):
1. if ts0 == 0, ts0 =1
2. totalCummulativePnl += pnl0 / ts0  
3. staker1.initialStakedPnl = totalCummulativePnl
4. prevPnl = pnl0

WHEN STAKER2 STAKE:
1. currentPnl = pnl1
2. currentStakedPnl = (currentPnl - prevPnl) / ts1
3. totalCummulativePnl += currentStakedPnl
4. staker2.initialStakedPnl = totalCummulativePnl
5. prevPnl = currentPnl(pnl1)

WHEN STAKER3 STAKE:
0. currentPnl = pnl2
1. currentStakedPnl = (currentPnl - prevPnl) / ts2
2. totalCummulativePnl += currentStakedPnl
3. staker3.initialStakedPnl = totalCummulativePnl
4. prevPnl = currentPnl(pnl2)

WHEN STAKER2 UNSTAKE:
1. currentPnl = pnl3
2. currentStakedPnl = (currentPnl - prevPnl) / ts3
3. totalCummulativePnl += currentStakedPnl
4. cummulativeGrowth = totalCummulativePnl - staker2.initialStakedPnl
5. profit = sa21 * cummulativeGrowth
6. PAY profit - send real money  (this profit will be excluded from total on the next step when we will calc pnl again)
7. prevPnl = currentPnl


Let's unwind the formula

WHEN STAKER2 UNSTAKE:

profit = sa21 * cummulativeGrowth = sa21 * [totalCummulativePnl - staker2.initialStakedPnl] =
= sa21 * [pnl0/ts0 + (pnl1 - pnl0)/ts1 + (pnl2 - pnl1)/ts2 + (pnl3 - pnl2)/ts3 - pnl0/ts0 - (pnl1 - pnl0) / ts1] =
= sa21 * [(pnl2 - pnl1)/ts2 + (pnl3 - pnl2)/ts3]


******************************************************************************
*/

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IStripsLpToken } from "../interface/IStripsLpToken.sol";
import { IStrips } from "../interface/IStrips.sol";
import { IRewarder } from "../interface/IRewarder.sol";
import { IMarket } from "../interface/IMarket.sol";
import { IStripsLpToken } from "../interface/IStripsLpToken.sol";
import { IUniswapV2Pair } from "../external/interfaces/IUniswapV2Pair.sol";
import { IStakeble } from "../interface/IStakeble.sol";
import { SignedBaseMath } from "../lib/SignedBaseMath.sol";

import { SLPToken } from "../token/SLPToken.sol";
import { Rewarder } from "../reward/Rewarder.sol";

library SlpFactoryImpl {
    using SignedBaseMath for int256;
    /*
        Factory method, to reduce contract size
        Creating code is huge
     */
    function _slpFactory(
        IStripsLpToken.TokenParams memory _params,
        string memory _name,
        string memory _symbol 
    ) external returns (IStripsLpToken) 
    {
        return new SLPToken(_params,
                            _name,
                            _symbol);
    }

    function _rewarderFactory(
        IRewarder.InitParams memory _params
    ) external returns (IRewarder)
    {
        return new Rewarder(_params);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IMarket } from "../interface/IMarket.sol";
import { IStrips } from "../interface/IStrips.sol";
import { IStripsLpToken } from "../interface/IStripsLpToken.sol";
import { IStakeble } from "../interface/IStakeble.sol";

import { SignedBaseMath } from "../lib/SignedBaseMath.sol";
import { IStripsLpToken } from "../interface/IStripsLpToken.sol";
import { IUniswapLpOracle } from "../interface/IUniswapLpOracle.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @title SLP token using for adding "stakebility" to any asset
 * @dev created by the asset. All calls for changing PNL are ownable:
 * Have 2 tokens by default:
 *  staking - the token that is using for staking to Asset (UNIV2 pair by default for the current version)
 *  trading - the token that is using for accumulating profit. By default it's USDC
 * @author Strips Finance
 **/
contract SLPToken is 
    IStripsLpToken,
    ERC20, 
    ReentrancyGuard,
    Ownable
{ 
    using SignedBaseMath for int256;

    // Developed to be able to track 2-tokens asset
    struct StakerData {
        bool exist;

        //save initial staking/trading cummulative PNL on staker's stake event.
        int256 initialStakingPnl;
        int256 initialTradingPnl;
        
        uint256 initialBlockNum;
        uint256 initialTimeStamp;

        //Save the current staking/trading unrealized profit when the staker stake 2+ time.
        int256 unrealizedStakingProfit;
        int256 unrealizedTradingProfit;
    }

    int256 public prevStakingPnl;
    int256 public prevTradingPnl;

    int256 public cummulativeStakingPnl;
    int256 public cummulativeTradingPnl;
    
    //For tracking trading/staking "growth", should be changed by the OWNER only 
    int256 public cumTradingPNL;
    int256 public cumStakingPNL;
        
    
    //All data setup on init
    TokenParams private params;
    mapping (address => StakerData) public stakers;

    /*To not have stack too deep error */
    struct InternalCalcs {
        int256 amount;
        int256 assetPnl;
        int256 currentTradingPnl;
        int256 currentStakingPnl;

        int256 instantCummulativeStakingPnl;
        int256 isntantCummulativeTradingPnl;

        int256 unstakeShare;
        int256 feeShare;
    }


    constructor(TokenParams memory _params,
                string memory _name,
                string memory _symbol) 
                ERC20(_name, _symbol) 
    {
        params = _params;
    }

    function changeTradingPnl(int256 amount) public override onlyOwner
    {
        cumTradingPNL += amount;
    }
    
    function changeStakingPnl(int256 amount) public override onlyOwner
    {
        cumStakingPNL += amount;
    }

    function claimProfit(address staker, uint256 amount) public override onlyOwner returns (int256 stakingProfit, int256 tradingProfit)
    {
        ProfitParams memory profit = calcProfit(staker, amount);
        if (profit.stakingFee > 0){
            changeStakingPnl(profit.stakingFee);
        }

        if (profit.lpProfit > 0){
            changeStakingPnl(profit.lpProfit);
        }

        if (profit.usdcLoss < 0){
            changeTradingPnl(profit.usdcLoss);
        }


        burn(staker, amount);

        stakingProfit = profit.unstakeAmountLP;
        tradingProfit = profit.unstakeAmountERC20;
    }


    function getPairPrice() external view override returns (int256)
    {
        return IUniswapLpOracle(params.pairOracle).getPrice();
    }

    function getBurnableToken() external view override returns (address)
    {
        return params.stakingToken;
    }

    function getParams() external view override returns (TokenParams memory)
    {   
        return params;
    }

    function checkOwnership() external view override onlyOwner returns (address) {
        //DO nothing, just revert if call is not from owner

        return owner();
    }

    function totalPnl() external view override returns (int256 usdcTotal, int256 lpTotal)
    {
        int256 unrealizedPnl = IStrips(params.stripsProxy).assetPnl(owner());

        usdcTotal = unrealizedPnl + cumTradingPNL;
        lpTotal = cumStakingPNL;
    }

    function stakingPnl() public view returns (int256 current, int256 cummulative)
    {
        address _owner = owner();
        int256 _totalSupply = int256(totalSupply());

        current = cumStakingPNL;

        if (_totalSupply == 0){
            cummulative = cummulativeStakingPnl + current;
        } else {
            cummulative = cummulativeStakingPnl + (current - prevStakingPnl).divd(_totalSupply);
        }

    }

    function tradingPnl() public view returns (int256 current, int256 cummulative)
    {
        address _owner = owner();
        int256 _totalSupply = int256(totalSupply());

        int256 assetPnl = IStrips(params.stripsProxy).assetPnl(_owner);

        current = assetPnl + cumTradingPNL;
        
        if (_totalSupply == 0){
            cummulative = cummulativeTradingPnl + current;
        } else {
            cummulative = cummulativeTradingPnl + (current - prevTradingPnl).divd(_totalSupply);
        }
    }


    function accumulatePnl() public override onlyOwner {
        int256 currentStakingPnl = 0;
        int256 currentTradingPnl = 0;

        (currentStakingPnl, cummulativeStakingPnl) = stakingPnl();
        prevStakingPnl = currentStakingPnl;


        (currentTradingPnl, cummulativeTradingPnl) = tradingPnl();
        prevTradingPnl = currentTradingPnl;
    }

    /*All checks should be made inside caller */
    function saveProfit(address staker) public override onlyOwner {
        int256 tokenBalance = int256(balanceOf(staker));
        
        stakers[staker].unrealizedStakingProfit += (cummulativeStakingPnl - stakers[staker].initialStakingPnl).muld(tokenBalance);
        stakers[staker].unrealizedTradingProfit += (cummulativeTradingPnl - stakers[staker].initialTradingPnl).muld(tokenBalance);
    }


    /*All checks should be made inside caller */
    function mint(address staker, uint256 amount) public override onlyOwner 
    {        
        stakers[staker] = StakerData({
            exist: true,

            initialStakingPnl:cummulativeStakingPnl,
            initialTradingPnl:cummulativeTradingPnl,
    
            initialBlockNum:block.number,
            initialTimeStamp:block.timestamp,

            unrealizedStakingProfit: stakers[staker].unrealizedStakingProfit,
            unrealizedTradingProfit: stakers[staker].unrealizedTradingProfit
        });

        _mint(staker, amount);
    }

    /*All checks should be made inside caller */
    function burn(address staker, uint256 amount) public override onlyOwner 
    {
        int256 burnShare = int256(amount).divd(int256(balanceOf(staker)));

        stakers[staker].unrealizedStakingProfit -= (stakers[staker].unrealizedStakingProfit.muld(burnShare));
        stakers[staker].unrealizedTradingProfit -= (stakers[staker].unrealizedTradingProfit.muld(burnShare));

        _burn(staker, amount);

        if (balanceOf(staker) == 0){
            delete stakers[staker];
        }
    }

    function canUnstake(address staker, uint256 amount) external view override
    {
        require(stakers[staker].exist, "NO_SUCH_STAKER");
        require(block.number > stakers[staker].initialBlockNum, "UNSTAKE_SAME_BLOCK");
        require(amount > 0 && balanceOf(staker) >= amount, "WRONG_UNSTAKE_AMOUNT");
    }

        


    /**
     * @dev Major view method that is using by frontend to view the current profit
     *  Here is how we show data on frontend (check ProfitParams below):
     *  1 - On major screen with the list of all stakes:
     *       totalStaked = 100 Lp tokens  (shows in LP amount of LP tokens user staked)
     *       stakingProfit (LP) = 10 LP ($10)  (shows the profit or loss that staker earned or lost in LP. Need to convert to USDC using profit.lpPrice)
     *       unstakeAmountERC20 (USDC) = -$100  (shows the profit or loss that staker earned in USDC)
     *       stakingFee = 1 LP (days left to 0 = penaltyLeft)
     *
     *  2 - on popup when staker select THE EXACT amount of SLP to unstake:
     *       profit.unstakeAmountLP (LP) = 100 LP ($100)   The amount that the staker will receive in LP, including collateral
     *       profit.unstakeAmountERC20 (USDC) = $10 | 0.   The amount that the staker will receive in USDC. Will be 0 if pnl is negative.
     *       _ hide the penalty
     *
     * @param staker staker address
     * @param amount amount of SLP tokens for unstake
     * @return profit ProfitParams all data that is required to show the profit, check IStripsLpToken interface
     *       struct ProfitParams
     *           // LP unstaked amount 
     *           int256 unstakeAmountLP;
     *
     *           //USDC unstaked amount  
     *           int256 unstakeAmountERC20;
     *
     *          //LP profit or loss not including collateral
     *           int256 stakingProfit;   
     *           
     *           //Fee that is paid if unstake in less than 7 days (paid in LP tokens)
     *           int256 stakingFee;
     *
     *          //Time in seconds left untill penalty will become 0
     *           int256 penaltyLeft;
     *
     *           //Collateral in LP that staker staked
     *           uint256 totalStaked;
     *
     *           //The current LP price (in USDC), using for conversion
     *           int256 lpPrice;
     **/
    function calcProfit(address staker, uint256 amount) public view override returns (ProfitParams memory profit)
    {
        profit.totalStaked = balanceOf(staker);
        require(amount > 0 && amount <= profit.totalStaked, "WRONG_AMOUNT");
        
        InternalCalcs memory internalCalcs;
        internalCalcs.amount = int256(amount);

        (internalCalcs.currentStakingPnl, 
            internalCalcs.instantCummulativeStakingPnl) = stakingPnl();
        
        (internalCalcs.currentTradingPnl, 
            internalCalcs.isntantCummulativeTradingPnl) = tradingPnl();

        internalCalcs.unstakeShare = internalCalcs.amount.divd(int256(profit.totalStaked));
        profit.stakingProfit = internalCalcs.amount.muld(internalCalcs.instantCummulativeStakingPnl - stakers[staker].initialStakingPnl) +  internalCalcs.unstakeShare.muld(stakers[staker].unrealizedStakingProfit);
        profit.unstakeAmountERC20 = internalCalcs.amount.muld(internalCalcs.isntantCummulativeTradingPnl - stakers[staker].initialTradingPnl) + internalCalcs.unstakeShare.muld(stakers[staker].unrealizedTradingProfit);

        (internalCalcs.feeShare, 
            profit.penaltyLeft) = calcFeeLeft(staker);

        profit.stakingFee = internalCalcs.amount.muld(internalCalcs.feeShare);
        profit.unstakeAmountLP = internalCalcs.amount + profit.stakingProfit - profit.stakingFee;

        profit.lpPrice = IUniswapLpOracle(params.pairOracle).getPrice();
        if (profit.unstakeAmountERC20 < 0){
            profit.usdcLoss = profit.unstakeAmountERC20;
            profit.lpProfit = -1 * profit.usdcLoss.divd(profit.lpPrice);
            profit.unstakeAmountLP = profit.unstakeAmountLP  - profit.lpProfit;

            profit.unstakeAmountERC20 = 0;
            
        }

    }
    

    /*
        2% fee during 7 days now.
    */
    function calcFeeLeft(
        address staker
    ) public view override returns (int256 feeShare, 
                                int256 periodLeft)
    {
        feeShare = 0;
        periodLeft = 0;

        int256 time_elapsed = int256(block.timestamp - stakers[staker].initialTimeStamp);

        if (time_elapsed >= params.penaltyPeriod){
            return (0, 0);
        }
        
        feeShare = params.penaltyFee - params.penaltyFee.divd(params.penaltyPeriod.toDecimal()).muld(time_elapsed.toDecimal());
        periodLeft = params.penaltyPeriod - time_elapsed;
    }

    function setPenaltyFee(int256 _fee) external override onlyOwner{
        require(_fee >= 0, "WRONG_FEE");

        params.penaltyFee = _fee;
    }

    function setParams(TokenParams memory _params) external override onlyOwner{
        params = _params;
    }


    function transfer(address recipient, uint256 amount) public override(ERC20, IERC20) returns (bool) {
        _transferStake(msg.sender, recipient, amount);

        return super.transfer(recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override(ERC20, IERC20) returns (bool) {
        _transferStake(sender, recipient, amount);

        return super.transferFrom(sender, recipient, amount);
    }

    function _transferStake(address sender, address recipient, uint256 amount) private {
        require(stakers[sender].exist, "STAKER_NOT_FOUND");
        require(stakers[recipient].exist == false, "MERGE_NOT_POSSIBLE");

        int256 transferShare = int256(amount / balanceOf(sender));

        stakers[recipient] = stakers[sender];

        int256 stakingProfit = transferShare * stakers[sender].unrealizedStakingProfit;
        int256 tradingProfit = transferShare * stakers[sender].unrealizedTradingProfit;

        if (stakingProfit != 0){
            stakers[sender].unrealizedStakingProfit -= stakingProfit;
            stakers[recipient].unrealizedStakingProfit = stakingProfit;
        }

        if (tradingProfit != 0){
            stakers[sender].unrealizedTradingProfit -= tradingProfit;
            stakers[recipient].unrealizedTradingProfit = tradingProfit;
        }

        if (amount == balanceOf(sender)){
            delete stakers[sender];
        }
    }

}

pragma solidity ^0.8.0;

// We are using 0.8.0 with safemath inbuilt
// Need to implement mul and div operations only
// We have 18 for decimal part and  58 for integer part. 58+18 = 76 + 1 bit for sign
// so the maximum is 10**58.10**18 (should be enough :) )

library SignedBaseMath {
    uint8 constant DECIMALS = 18;
    int256 constant BASE = 10**18;
    int256 constant BASE_PERCENT = 10**16;

    /*Use this to convert USDC 6 decimals to 18 decimals */
    function to18Decimal(int256 x, uint8 tokenDecimals) internal pure returns (int256) {
        require(tokenDecimals < DECIMALS);
        return x * int256(10**(DECIMALS - tokenDecimals));
    }

    /*Use this to convert USDC 18 decimals back to original 6 decimal and send it */
    function from18Decimal(int256 x, uint8 tokenDecimals) internal pure returns (int256) {
        require(tokenDecimals < DECIMALS);
        return x / int256(10**(DECIMALS - tokenDecimals));
    }


    function toDecimal(int256 x, uint8 decimals) internal pure returns (int256) {
        return x * int256(10**decimals);
    }

    function toDecimal(int256 x) internal pure returns (int256) {
        return x * BASE;
    }

    function oneDecimal() internal pure returns (int256) {
        return 1 * BASE;
    }

    function tenPercent() internal pure returns (int256) {
        return 10 * BASE_PERCENT;
    }

    function ninetyPercent() internal pure returns (int256) {
        return 90 * BASE_PERCENT;
    }

    function onpointOne() internal pure returns (int256) {
        return 110 * BASE_PERCENT;
    }


    function onePercent() internal pure returns (int256) {
        return 1 * BASE_PERCENT;
    }

    function muld(int256 x, int256 y) internal pure returns (int256) {
        return _muld(x, y, DECIMALS);
    }

    function divd(int256 x, int256 y) internal pure returns (int256) {
        if (y == 1){
            return x;
        }
        return _divd(x, y, DECIMALS);
    }

    function _muld(
        int256 x,
        int256 y,
        uint8 decimals
    ) internal pure returns (int256) {
        return (x * y) / unit(decimals);
    }

    function _divd(
        int256 x,
        int256 y,
        uint8 decimals
    ) internal pure returns (int256) {
        return (x * unit(decimals)) / y;
    }

    function unit(uint8 decimals) internal pure returns (int256) {
        return int256(10**uint256(decimals));
    }
}

pragma solidity ^0.8.0;

import { SignedBaseMath } from "./SignedBaseMath.sol";
import { IMarket } from "../interface/IMarket.sol";
import { IStrips } from "../interface/IStrips.sol";
import { IAssetOracle } from "../interface/IAssetOracle.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IStripsLpToken } from "../interface/IStripsLpToken.sol";
import { IUniswapLpOracle } from "../interface/IUniswapLpOracle.sol";
import { IUniswapV2Pair } from "../external/interfaces/IUniswapV2Pair.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IRewarder } from "../interface/IRewarder.sol";

library StorageMarketLib {
    using SignedBaseMath for int256;

    /* Params that are set on contract creation */
    struct InitParams {
        IStrips stripsProxy;
        IAssetOracle assetOracle;
        IUniswapLpOracle pairOracle;

        int256 initialPrice;
        int256 burningCoef;

        IUniswapV2Pair stakingToken;
        IERC20 tradingToken;
        IERC20 strpToken;       
    }

    //Need to care about align here 
    struct State {
        address dao;

        InitParams params;
        IStripsLpToken slpToken;
        IRewarder rewarder;

        int256 totalLongs; //Real notional 
        int256 totalShorts; //Real notional
        
        int256 demand; //included proportion
        int256 supply; //included proportion
        
        int256 ratio;
        int256 _prevLiquidity;
        bool isSuspended;

        address sushiRouter;
        uint createdAt;
    }

    function pairPrice(
        State storage state
    ) internal view returns (int256){
        return state.params.pairOracle.getPrice();
    }

    //If required LP price conversions should be made here
    function calcStakingLiqudity(
        State storage state
    ) internal view returns (int256){
        return int256(state.params.stakingToken.balanceOf(address(this)));
    }

    function calcTradingLiqudity(
        State storage state
    ) internal view returns (int256){
        return int256(state.params.tradingToken.balanceOf(address(this)));
    }

    function getLiquidity(
        State storage state
    ) internal view returns (int256) {
        int256 stakingLiquidity = calcStakingLiqudity(state);
        
        if (stakingLiquidity != 0){
            stakingLiquidity = stakingLiquidity.muld(pairPrice(state)); //convert LP to USDC
        }

        return stakingLiquidity + calcTradingLiqudity(state);
    }

    //Should return the scalar
    //TODO: change to stackedLiquidity + total_longs_pnl + total_shorts_pnl
    function maxNotional(
        State storage state
    ) internal view returns (int256) {
        int256 _liquidity = getLiquidity(state);

        if (_liquidity <= 0){
            return 0;
        }
        int256 unrealizedPnl = state.params.stripsProxy.assetPnl(address(this));
        int256 exposure = state.totalLongs - state.totalShorts;
        if (exposure < 0){
            exposure *= -1;
        }

        //10% now. TODO: allow setup via Params
        return (_liquidity + unrealizedPnl - exposure).muld(10 * SignedBaseMath.onePercent());
    }


    function getPrices(
        State storage state
    ) internal view returns (int256 marketPrice, int256 oraclePrice){
        marketPrice = currentPrice(state);

        oraclePrice = IAssetOracle(state.params.assetOracle).getPrice();
    }

    function currentPrice(
        State storage state
    ) internal view returns (int256) {
        return state.params.initialPrice.muld(state.ratio);
    }


    function oraclePrice(
        State storage state
    ) internal view returns (int256) {
        return IAssetOracle(state.params.assetOracle).getPrice();
    }

    function approveStrips(
        State storage state,
        IERC20 _token,
        int256 _amount
    ) internal {
        require(_amount > 0, "BAD_AMOUNT");

        SafeERC20.safeApprove(_token, 
                                address(state.params.stripsProxy), 
                                uint(_amount));
    }
    
    function _updateRatio(
        State storage state,
        int256 _longAmount,
        int256 _shortAmount
    ) internal
    {
        int256 _liquidity = getLiquidity(state); 
        if (state._prevLiquidity == 0){
            state.supply = _liquidity.divd(SignedBaseMath.oneDecimal() + state.ratio);
            state.demand = state.supply.muld(state.ratio);
            state._prevLiquidity = _liquidity;
        }

        int256 diff = _liquidity - state._prevLiquidity;

        state.demand += (_longAmount + diff.muld(state.ratio.divd(SignedBaseMath.oneDecimal() + state.ratio)));
        state.supply += (_shortAmount + diff.divd(SignedBaseMath.oneDecimal() + state.ratio));
        if (state.demand <= 0 || state.supply <= 0){
            require(0 == 1, "SUSPENDED");
        }

        state.ratio = state.demand.divd(state.supply);
        state._prevLiquidity = _liquidity;
    }


    // we need this to be VIEW to use for priceChange calculations
    function _whatIfRatio(
        State storage state,
        int256 _longAmount,
        int256 _shortAmount
    ) internal view returns (int256){
        int256 ratio = state.ratio;
        int256 supply = state.supply;
        int256 demand = state.demand;
        int256 prevLiquidity = state._prevLiquidity;

        int256 _liquidity = getLiquidity(state);
        
        if (prevLiquidity == 0){
            supply = _liquidity.divd(SignedBaseMath.oneDecimal() + ratio);
            demand = supply.muld(ratio);
            prevLiquidity = _liquidity;
        }

        int256 diff = _liquidity - prevLiquidity;

        demand += (_longAmount + diff.muld(ratio.divd(SignedBaseMath.oneDecimal() + ratio)));
        supply += (_shortAmount + diff.divd(SignedBaseMath.oneDecimal() + ratio));
        if (demand <= 0 || supply <= 0){
            require(0 == 1, "SUSPENDED");
        }

        return demand.divd(supply);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function renounceRole(bytes32 role, address account) public virtual override {
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
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

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
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

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity >=0.8.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IInsuranceFund {
    function withdraw(address _to, int256 _amount) external;

    function getLiquidity() external view returns (int256);
    function getPartedLiquidity() external view returns (int256 usdcLiquidity, int256 lpLiquidity);
}

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IMarket } from "../interface/IMarket.sol";
import { IStrips } from "../interface/IStrips.sol";
import { IStakeble } from "../interface/IStakeble.sol";
import { IAssetOracle } from "../interface/IAssetOracle.sol";
import { IInsuranceFund } from "../interface/IInsuranceFund.sol";
import { IStripsLpToken } from "../interface/IStripsLpToken.sol";

import { SignedBaseMath } from "./SignedBaseMath.sol";
import { StorageMarketLib } from "./StorageMarket.sol";

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


library StorageStripsLib {
    using SignedBaseMath for int256;
    
    struct MarketData {
        bool created;

        //TODO: any data about the
    }

    struct Position {
        IMarket market; //can be removed
        address trader;

        int256 initialPrice; //will become avg on _aggregation
        int256 entryPrice;   // always the "new market price"
        int256 prevAvgPrice; 

        int256 collateral; 
        int256 notional; 

        uint256 initialTimestamp;
        uint256 cummulativeIndex; 
        uint256 initialBlockNumber;
        uint256 posIndex;           // use this to find position by index
        uint256 lastChangeBlock;

        int256 unrealizedPnl;   //used to save funding_pnl for aggregation
        
        //TODO: refactor this
        bool isLong;
        bool isActive;
        bool isLiquidated;  
        
        //used only for AMM
        bool isAmm;
        int256 savedTradingPnl;    // use this to deal with div to zero when ammUpdatedNotional == 0
        int256 zeroParameter;
        int256 lastNotional;      // for amm we calculate funding based on notional from prev block always
        int256 lastInitialPrice;  // for amm
        bool lastIsLong;

        int256 oraclePriceUsed;
    }

    struct RiskParams {
        int256 fundFeeRatio; //the part of fee that goes to Fee Fund. insuranceFeeRatio = 1 - fundFeeRatio 
        int256 daoFeeRatio;

        int256 liquidatorFeeRatio; // used to calc the liquidator reward insuranceLiquidationFeeRatio = 1 - liquidatorFeeRatio
        int256 marketFeeRatio; // used to calc market ratio on Liquidation
        int256 insuranceProfitOnPositionClosed;

        int256 liquidationMarginRatio; // the minimum possible margin ratio.
        int256 minimumPricePossible; //use this when calculate fee
    }

    struct OracleData {
        bool isActive;
        int256 keeperReward; 
    }

    /*Use this struct for fast access to position */
    struct PositionMeta {
        bool isActive; // is Position active

        address _account; 
        IMarket _market;
        uint _posIndex;
    }


    //GENERAL STATE - keep aligned on update
    struct State {
        address dao;
        bool isSuspended;

        /*Markets data */
        IMarket[] allMarkets;
        mapping (IMarket => MarketData) markets;

        /*Traders data */
        address[] allAccounts; // never pop
        mapping (address => bool) existingAccounts; // so to not add twice, and have o(1) check for addin

        mapping (address => mapping(IMarket => Position)) accounts; 
        
        uint[] allIndexes;  // if we need to loop through all positions we use this array. Reorder it to imporove effectivenes
        mapping (uint => PositionMeta) indexToPositionMeta;
        uint256 currentPositionIndex; //index of the latest created position

        /*Oracles */
        address[] allOracles;
        mapping(address => OracleData) oracles;

        /*Strips params */
        RiskParams riskParams;
        IInsuranceFund insuranceFund;
        IERC20 tradingToken;

        // last ping timestamp
        uint256 lastAlive;
        // the time interval during which contract methods are available that are marked with a modifier ifAlive
        uint256 keepAliveInterval;

        address lpOracle;
    }

    /*
        Oracles routines
    */
    function addOracle(
        State storage state,
        address _oracle,
        int256 _keeperReward
    ) internal {
        require(state.oracles[_oracle].isActive == false, "ORACLE_EXIST");
        
        state.oracles[_oracle].keeperReward = _keeperReward;
        state.oracles[_oracle].isActive = true;

        state.allOracles.push(_oracle);
    }

    function removeOracle(
        State storage state,
        address _oracle
    ) internal {
        require(state.oracles[_oracle].isActive == true, "NO_SUCH_ORACLE");
        state.oracles[_oracle].isActive = false;
    }


    function changeOracleReward(
        State storage state,
        address _oracle,
        int256 _newReward
    ) internal {
        require(state.oracles[_oracle].isActive == true, "NO_SUCH_ORACLE");
        state.oracles[_oracle].keeperReward = _newReward;
    }


    /*
    *******************************************************
    *   getters/setters for adding/removing data to state
    *******************************************************
    */

    function setInsurance(
        State storage state,
        IInsuranceFund _insurance
    ) internal
    {
        require(address(_insurance) != address(0), "ZERO_INSURANCE");
        require(address(state.insuranceFund) == address(0), "INSURANCE_EXIST");

        state.insuranceFund = _insurance;
    }

    function getMarket(
        State storage state,
        IMarket _market
    ) internal view returns (MarketData storage market) {
        market = state.markets[_market];
        require(market.created == true, "NO_MARKET");
    }

    function addMarket(
        State storage state,
        IMarket _market
    ) internal {
        MarketData storage market = state.markets[_market];
        require(market.created == false, "MARKET_EXIST");

        state.markets[_market].created = true;
        state.allMarkets.push(_market);
    }

    function setRiskParams(
        State storage state,
        RiskParams memory _riskParams
    ) internal{
        state.riskParams = _riskParams;
    }



    // Not optimal 
    function checkPosition(
        State storage state,
        IMarket _market,
        address account
    ) internal view returns (Position storage){
        return state.accounts[account][_market];
    }

    // Not optimal 
    function getPosition(
        State storage state,
        IMarket _market,
        address _account
    ) internal view returns (Position storage position){
        position = state.accounts[_account][_market];
        require(position.isActive == true, "NO_POSITION");
    }

    function setPosition(
        State storage state,
        IMarket _market,
        address account,
        bool isLong,
        int256 collateral,
        int256 notional,
        int256 initialPrice,
        bool merge
    ) internal returns (uint256 index) {
        
        /*TODO: remove this */
        if (state.existingAccounts[account] == false){
            state.allAccounts.push(account); 
            state.existingAccounts[account] = true;
        }
        Position storage _position = state.accounts[account][_market];

        /*
            Update PositionMeta for faster itterate over positions.
            - it MUST be trader position
            - it should be closed or liquidated. 

            We DON'T update PositionMeta if it's merge of the position
         */
        if (address(_market) != account && _position.isActive == false)
        {            
            /*First ever position for this account-_market setup index */
            if (_position.posIndex == 0){
                if (state.currentPositionIndex == 0){
                    state.currentPositionIndex = 1;  // posIndex started from 1, to be able to do check above
                }

                _position.posIndex = state.currentPositionIndex;

                state.allIndexes.push(_position.posIndex);
                state.indexToPositionMeta[_position.posIndex] = PositionMeta({
                    isActive: true,
                    _account: account,
                    _market: _market,
                    _posIndex: _position.posIndex
                });

                /*INCREMENT index only if unique position was created */
                state.currentPositionIndex += 1;                
            }else{
                /*We don't change index if it's old position, just need to activate it */
                state.indexToPositionMeta[_position.posIndex].isActive = true;
            }
        }

        index = _position.posIndex;

        _position.trader = account;
        _position.lastChangeBlock = block.number;
        _position.isActive = true;
        _position.isLiquidated = false;

        _position.isLong = isLong;
        _position.market = _market;
        _position.cummulativeIndex = _market.currentOracleIndex();
        _position.initialTimestamp = block.timestamp;
        _position.initialBlockNumber = block.number;
        _position.entryPrice = initialPrice;

        int256 avgPrice = initialPrice;
        int256 prevAverage = _position.prevAvgPrice;
        if (prevAverage != 0){
            int256 prevNotional = _position.notional; //save 1 read
            avgPrice =(prevAverage.muld(prevNotional) + initialPrice.muld(notional)).divd(notional + prevNotional);
        }
        
        
        _position.prevAvgPrice = avgPrice;

        
        if (merge == true){
            _position.collateral +=  collateral; 
            _position.notional += notional;
            _position.initialPrice = avgPrice;
        }else{
            _position.collateral = collateral;
            _position.notional = notional;
            _position.initialPrice = initialPrice;
            
            //It's AMM need to deal with that in other places        
            if (address(_market) == account){
                _position.isAmm = true;
                _position.lastNotional = notional;
                _position.lastInitialPrice = initialPrice;
            }
        }
    }

    function unsetPosition(
        State storage state,
        Position storage _position
    ) internal {
        if (_position.isActive == false){
            return;
        } 

        /*
            Position is fully closed or liquidated, NEED to update PositionMeta 
            BUT
            we never reset the posIndex
        */
        state.indexToPositionMeta[_position.posIndex].isActive = false;

        _position.lastChangeBlock = block.number;
        _position.isActive = false;

        _position.entryPrice = 0;
        _position.collateral = 0; 
        _position.notional = 0; 
        _position.initialPrice = 0;
        _position.cummulativeIndex = 0;
        _position.initialTimestamp = 0;
        _position.initialBlockNumber = 0;
        _position.unrealizedPnl = 0;
        _position.prevAvgPrice = 0;
    }

    function partlyClose(
        State storage state,
        Position storage _position,
        int256 collateral,
        int256 notional,
        int256 unrealizedPaid
    ) internal {
        _position.collateral -= collateral; 
        _position.notional -= notional;
        _position.unrealizedPnl -= unrealizedPaid;
        _position.lastChangeBlock = block.number;
    }

    /*
    *******************************************************
    *******************************************************
    *   Liquidation related functions
    *******************************************************
    *******************************************************
    */
    function getLiquidationRatio(
        State storage state
    ) internal view returns (int256){
        return state.riskParams.liquidationMarginRatio;
    }


    //Integrity check outside
    function addCollateral(
        State storage state,
        Position storage _position,
        int256 collateral
    ) internal {
        _position.collateral += collateral;
    }

    function removeCollateral(
        State storage state,
        Position storage _position,
        int256 collateral
    ) internal {
        _position.collateral -= collateral;
        
        require(_position.collateral >= 0, "COLLATERAL_TOO_BIG");
    }



    /*
    *******************************************************
    *   Funds view/transfer utils
    *******************************************************
    */
    function depositToDao(
        State storage state,
        address _from,
        int256 _amount
    ) internal {
        require(_amount > 0, "WRONG_AMOUNT");
        require(state.dao != address(0), "ZERO_DAO");
        
        if (_from == address(this)){
            SafeERC20.safeTransfer(state.tradingToken,
                                        state.dao, 
                                        uint(_amount));

        }else{
            SafeERC20.safeTransferFrom(state.tradingToken, 
                                        _from, 
                                        state.dao, 
                                        uint(_amount));
        }

    }

    function depositToMarket(
        State storage state,
        IMarket _market,
        address _from,
        int256 _amount
    ) internal {
        require(_amount > 0, "WRONG_AMOUNT");

        getMarket(state, _market);

        if (_from == address(this)){
            SafeERC20.safeTransfer(state.tradingToken, 
                                        address(_market), 
                                        uint(_amount));

        }else{
            SafeERC20.safeTransferFrom(state.tradingToken, 
                                        _from, 
                                        address(_market), 
                                        uint(_amount));
        }

        IStakeble(address(_market)).externalLiquidityChanged();

        IStakeble(address(_market)).changeTradingPnl(_amount);
    }
    
    function withdrawFromMarket(
        State storage state,
        IMarket _market,
        address _to,
        int256 _amount
    ) internal {
        require(_amount > 0, "WRONG_AMOUNT");

        getMarket(state, _market);

        IStakeble(address(_market)).ensureFunds(_amount);

        IStakeble(address(_market)).approveStrips(state.tradingToken, _amount);
        SafeERC20.safeTransferFrom(state.tradingToken, 
                                    address(_market), 
                                    _to, 
                                    uint(_amount));

        IStakeble(address(_market)).externalLiquidityChanged();

        IStakeble(address(_market)).changeTradingPnl(0 - _amount);
    }

    function depositToInsurance(
        State storage state,
        address _from,
        int256 _amount
    ) internal {
        require(address(state.insuranceFund) != address(0), "BROKEN_INSURANCE_ADDRESS");

        if (_from == address(this)){
            SafeERC20.safeTransfer(state.tradingToken, 
                                        address(state.insuranceFund), 
                                        uint(_amount));
        }else{
            SafeERC20.safeTransferFrom(state.tradingToken, 
                                        _from, 
                                        address(state.insuranceFund), 
                                        uint(_amount));
        }

        IStakeble(address(state.insuranceFund)).externalLiquidityChanged();

        IStakeble(address(state.insuranceFund)).changeTradingPnl(_amount);

    }
    
    function withdrawFromInsurance(
        State storage state,
        address _to,
        int256 _amount
    ) internal {
        
        require(address(state.insuranceFund) != address(0), "BROKEN_INSURANCE_ADDRESS");

        IStakeble(address(state.insuranceFund)).ensureFunds(_amount);

        state.insuranceFund.withdraw(_to, _amount);

        IStakeble(address(state.insuranceFund)).changeTradingPnl(0 - _amount);
    }


}

interface IStripsEvents {
    event LogCheckData(
        address indexed account,
        address indexed market,
        CheckParams params
    );

    event LogCheckInsuranceData(
        address indexed insurance,
        CheckInsuranceParams params
    );

    struct CheckInsuranceParams{
        int256 lpLiquidity;
        int256 usdcLiquidity;
        uint256 sipTotalSupply;
    }

    // ============ Structs ============

    struct CheckParams{
        /*Integrity Checks */        
        int256 marketPrice;
        int256 oraclePrice;
        int256 tradersTotalPnl;
        int256 uniLpPrice;
        
        /*Market params */
        bool ammIsLong;
        int256 ammTradingPnl;
        int256 ammFundingPnl;
        int256 ammTotalPnl;
        int256 ammNotional;
        int256 ammInitialPrice;
        int256 ammEntryPrice;
        int256 ammTradingLiquidity;
        int256 ammStakingLiquidity;
        int256 ammTotalLiquidity;

        /*Trading params */
        bool isLong;
        int256 tradingPnl;
        int256 fundingPnl;
        int256 totalPnl;
        int256 marginRatio;
        int256 collateral;
        int256 notional;
        int256 initialPrice;
        int256 entryPrice;

        /*Staking params */
        int256 slpTradingPnl;
        int256 slpStakingPnl;
        int256 slpTradingCummulativePnl;
        int256 slpStakingCummulativePnl;
        int256 slpTradingPnlGrowth;
        int256 slpStakingPnlGrowth;
        int256 slpTotalSupply;

        int256 stakerInitialStakingPnl;
        int256 stakerInitialTradingPnl;
        uint256 stakerInitialBlockNum;
        int256 stakerUnrealizedStakingProfit;
        int256 stakerUnrealizedTradingProfit;

        /*Rewards params */
        int256 tradingRewardsTotal; 
        int256 stakingRewardsTotal;
    }
}

library StripsEvents {
    event LogCheckData(
        address indexed account,
        address indexed market,
        IStripsEvents.CheckParams params
    );

    event LogCheckInsuranceData(
        address indexed insurance,
        IStripsEvents.CheckInsuranceParams params
    );


    function logCheckData(address _account,
                            address _market, 
                            IStripsEvents.CheckParams memory _params) internal {
        
        emit LogCheckData(_account,
                        _market,
                        _params);
    }

    function logCheckInsuranceData(address insurance,
                                    IStripsEvents.CheckInsuranceParams memory _params) internal {
        
        emit LogCheckInsuranceData(insurance,
                                    _params);
    }

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

interface IStakebleEvents {
    event LogUnstake(
        address indexed asset,
        address indexed staker,

        int256 slpAmount,
        int256 stakingProfit,
        int256 tradingProfit
    );
}

library StakebleEvents {
    event LogUnstake(
        address indexed asset,
        address indexed staker,

        int256 slpAmount,
        int256 stakingProfit,
        int256 tradingProfit
    );

    function logUnstakeData(address _asset,
                            address _staker,
                            int256 _slpAmount,
                            int256 _stakingProfit,
                            int256 _tradingProfit) internal {
        
        emit LogUnstake(_asset,
                        _staker,

                        _slpAmount,
                        _stakingProfit,
                        _tradingProfit);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {

  /**
   * @notice checks if the contract requires work to be done.
   * @param checkData data passed to the contract when checking for upkeep.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with,
   * if upkeep is needed.
   */
  function checkUpkeep(
    bytes calldata checkData
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData
    );

  /**
   * @notice Performs work on the contract. Executed by the keepers, via the registry.
   * @param performData is the data which was passed back from the checkData
   * simulation.
   */
  function performUpkeep(
    bytes calldata performData
  ) external;
}

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

interface IUniswapLpOracle is KeeperCompatibleInterface {
    function getPrice() external view returns (int256);
    function strpPrice() external view returns (int256);
}

pragma solidity ^0.8.0;

import { StorageMarketLib } from "../lib/StorageMarket.sol";

abstract contract MState
{
    StorageMarketLib.State public m_state;
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

import { IAssetOracle } from "../interface/IAssetOracle.sol";
import { IStrips } from "../interface/IStrips.sol";
import { SignedBaseMath } from "../lib/SignedBaseMath.sol";


contract AssetOracle is IAssetOracle
{
    using SignedBaseMath for int256;

    address public stripsProxy;
    address public keeper;
    uint public lastTimeStamp;

    int256 public lastApr;

    uint256 public lastCumulativeIndex;
    uint256 public lastBlockNumUpdate;
    int256[] public cumulativeOracleAvg;

    int256 constant ANN_PERIOD_SEC = 31536000;
    
    modifier activeOnly() {
        require(lastTimeStamp != 0, "NOT_ACTIVE");
         _;
    }

    modifier keeperOnly() {
        require(msg.sender == keeper, "NOT_A_KEEPER");
         _;
    }

    constructor(
        address _stripsProxy,
        address _keeper
    ){
        require(_keeper != address(0), "BROKEN_KEEPER");
        require(Address.isContract(_stripsProxy), "STRIPS_NOT_A_CONTRACT");

        stripsProxy = _stripsProxy;
        keeper = _keeper;
    }

    function getPrice() external view override activeOnly returns (int256){
        return lastApr;
    }

    function changeKeeper(address _keeper) external keeperOnly {
        keeper = _keeper;
    }

    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory) {
        if (block.timestamp > lastTimeStamp){
            upkeepNeeded = true;
        }else{
            upkeepNeeded = false;
        }
    }

    function accumulateOracle() internal {
        int256 aprPerSec = lastApr / ANN_PERIOD_SEC;

        if (lastCumulativeIndex != 0){
            aprPerSec += cumulativeOracleAvg[lastCumulativeIndex-1];
        }

        cumulativeOracleAvg.push(aprPerSec);
        lastCumulativeIndex += 1;
    }

    function performUpkeep(bytes calldata _data) public virtual override keeperOnly {
        require(block.timestamp > lastTimeStamp, "NO_NEED_UPDATE");
        lastTimeStamp = block.timestamp;

        lastApr = abi.decode(_data, (int256));

        //TODO: calc and set APY here
        accumulateOracle();
    }

    function calcOracleAverage(uint256 fromIndex) external view virtual override activeOnly returns (int256) {        
        require(lastCumulativeIndex > 0, "ORACLE_NEVER_UPDATED");

        int256 avg = cumulativeOracleAvg[lastCumulativeIndex-1];

        int256 len = int256(lastCumulativeIndex - fromIndex);
        if (len == 0){
            if (fromIndex > 1){
                return avg - cumulativeOracleAvg[fromIndex-2];
            }else{
                return avg;
            }
        }

        if (fromIndex != 0){
            avg -= cumulativeOracleAvg[fromIndex-1];
        }

        return avg / len;
    }
}

pragma solidity >=0.8.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.8.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    constructor() {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

    constructor() {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SignedBaseMath } from "../lib/SignedBaseMath.sol";
import { IRewarder } from "../interface/IRewarder.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title Rewarder contract
 * @dev Tracks stakers' and traders' contributions, calculates and pays rewards in SRP token.
 * Deployed per asset (per market) as a separate instance.
 * @author Strips Finance
 **/
contract Rewarder is IRewarder {
    bool private lock;
    address public owner;


    using SignedBaseMath for int256;

    modifier onlyOwner() {
        require(msg.sender == owner, "NOT_AN_OWNER");
         _;
    }

    modifier onlyAdmin() {
        require(msg.sender == params.admin, "NOT_AN_ADMIN");
         _;
    }

    modifier onlyStripsOrOwner() {
        require(msg.sender == owner || msg.sender == params.stripsProxy, "NOT_AN_OWNER_OR_STRIPS");
         _;
    }

    modifier nonReentrant() {
        require(lock == false, "ReentrancyGuard: reentrant call");

        lock = true;
        _;
        lock = false;
    }

    InitParams public params;

    // Info on each participant of the reward program (common for both traders and stakers)
    struct TraderInfo {
        bool isClaimed;

        /*Time when the position was opened. Use that to detect wash trades */
        uint256 lastTradeTime;

        /*Number of period when the trader did his last trade */
        uint256 lastPeriod;
        
        /* The value of total AMM trading volume for lastPeriod */
        int256 accInitial;
        
        /*Cummulative trader's trade volume for the period */
        int256 periodTradingVolume;

        /*Total current reward, it's not go to 0 if trader goes inactive, as you can claim at anytime */
        int256 reward;
    }

    struct StakerInfo{
        uint256 timeInitial;
        int256 accInitial;

        int256 slp;
        int256 reward;
    }

    int256 public totalTradingRewardsClaimed;
    int256 public totalStakingRewardsClaimed;

    uint256 public currentPeriod;
    uint256 public startTime;

    /*Staking */
    uint256 public lastStakeTime;
    int256 public supplyStakeTotal;
    int256 public accStakeTotal;

    /*Trading */
    uint256 public lastTradeTime;
    int256 public tradingVolumeTotal;
    int256 public accTradeTotal;


    mapping(uint256 => int256) public accPerPeriod;
    mapping(address => TraderInfo) public traders;
    mapping(address => StakerInfo) public stakers;

    constructor(
        InitParams memory _params
    ) {
        params = _params;
        owner = msg.sender;
        startTime = 0;

        totalTradingRewardsClaimed = 0;
        totalStakingRewardsClaimed = 0;
    }

    function currentTradingReward() external view override returns(int256)
    {
        return params.rewardTotalPerSecTrader;
    }

    function currentStakingReward() external view override returns (int256)
    {
        return params.rewardTotalPerSecStaker;
    }


    function changeTradingReward(int256 _newRewardPerSec) external onlyAdmin
    {
        bool isSwitched = _updatePeriod(0);

        if (!isSwitched && tradingVolumeTotal > 0){
            int256 timeDiff = int256(block.timestamp - lastTradeTime);
            accTradeTotal += timeDiff.toDecimal().muld(params.rewardTotalPerSecTrader).divd(tradingVolumeTotal);

        }

        params.rewardTotalPerSecTrader = _newRewardPerSec;
        lastTradeTime = block.timestamp;
    }

    function changeStakingReward(int256 _newRewardPerSec) external onlyAdmin
    {
        int256 timeDiff = int256(block.timestamp - lastStakeTime);
        accStakeTotal += timeDiff.toDecimal().muld(params.rewardTotalPerSecStaker).divd(supplyStakeTotal);

        params.rewardTotalPerSecStaker = _newRewardPerSec;
        lastStakeTime = block.timestamp;
    }


    function changeDao(address _newDao) external onlyAdmin
    {
        require(_newDao != address(0), "ZERO_DAO");
        params.dao = _newDao;
    }

    function changeOwner(address _newOwner) external onlyAdmin
    {
        require(_newOwner != address(0), "ZERO_OWNER");
        owner = _newOwner;
    }

    function changeAdmin(address _newAdmin) external onlyAdmin
    {
        require(_newAdmin != address(0), "ZERO_ADMIN");
        params.admin = _newAdmin;
    }


    /**
     * @dev Should be called each time someone stake/unstake.
     * @param _staker address of the staker
     **/
    function rewardStaker(address _staker) external override nonReentrant onlyStripsOrOwner {
        /*Accumulare reward for previous period and update accumulator */
        stakers[_staker].reward = totalStakerReward(_staker);

        /*Accumulate for the previous period if there was any supply */
        if (supplyStakeTotal > 0){
            int256 timeDiff = int256(block.timestamp - lastStakeTime);
            accStakeTotal += timeDiff.toDecimal().muld(params.rewardTotalPerSecStaker).divd(supplyStakeTotal);
        }
        lastStakeTime = block.timestamp;
        supplyStakeTotal = int256(params.slpToken.totalSupply());

        /*Update staker's stake*/
        stakers[_staker].accInitial = accStakeTotal;
        stakers[_staker].slp = int256(params.slpToken.balanceOf(_staker));
        stakers[_staker].timeInitial = block.timestamp;
    }

    function claimStakingReward(address _staker) external override {

        /*Accumulare reward and update staker's initial */
        //stakers[_staker].reward = totalStakerReward(_staker).muld(params.rewardTotalPerSecStaker);
        stakers[_staker].reward = totalStakerReward(_staker);

        if (stakers[_staker].reward <= 0){
            return;
        }

        int256 accInstant = accStakeTotal;
        if (supplyStakeTotal > 0){
            int256 timeDiff = int256(block.timestamp - lastStakeTime);
            accInstant += timeDiff.toDecimal().muld(params.rewardTotalPerSecStaker).divd(supplyStakeTotal);
        }


        SafeERC20.safeTransferFrom(params.strpToken, 
                                    params.dao, 
                                    _staker, 
                                    uint(stakers[_staker].reward));
        
        emit StakingRewardClaimed(
            _staker, 
            stakers[_staker].reward
        );

        totalStakingRewardsClaimed += stakers[_staker].reward;

        /*Reset reward and time*/
        stakers[_staker].reward = 0;
        stakers[_staker].timeInitial = block.timestamp;
        stakers[_staker].accInitial = accInstant;
    }

    function totalStakerReward(address _staker) public view override returns (int256 reward){
        /*If staker didn't stake he can't have reward yet */
        if (stakers[_staker].timeInitial == 0){
            return 0;
        }

        /*if supply is 0 it means that everyone usntake and no more accumulation */
        if (supplyStakeTotal <= 0){
            return stakers[_staker].reward;
        }

        /*Accumulate reward till current time */
        int256 timeDiff = int256(block.timestamp - lastStakeTime);
        int256 accInstant = accStakeTotal + timeDiff.toDecimal().muld(params.rewardTotalPerSecStaker).divd(supplyStakeTotal);

        return stakers[_staker].reward + stakers[_staker].slp.muld(accInstant - stakers[_staker].accInitial);
    }


    function totalTradeReward(address _trader) public view override returns (int256 reward){
        uint256 traderLastTrade = traders[_trader].lastTradeTime;

        /*If trader didn't or no one trade then it's 0 */
        if (traderLastTrade == 0 || lastTradeTime == 0){
            return 0;
        }

        /* What's the number of the current period? */
        uint256 _period = (block.timestamp - startTime) / params.periodLength;

        /*Which period the trader last trade */
        uint256 traderLastPeriod = traders[_trader].lastPeriod;

        int256 accInstant = 0;
        /* Accumulate reward for the previous period - ONLY till the end of period */
        if (_period > traderLastPeriod){
            accInstant = accPerPeriod[traderLastPeriod];
            if (accInstant == 0){
                /* updatePeriod never called. Need to calc accumulator first */
                /* |t(1)----period1---(traderLastTrade)----(lastTradeTime)<----timeDiff---->|(end of period)------call HERE| */

                if (tradingVolumeTotal <= 0){
                    return traders[_trader].reward;
                }

                uint256 timeLeft = params.periodLength - (lastTradeTime - startTime) % params.periodLength;
                accInstant = accTradeTotal + int256(timeLeft).toDecimal().muld(params.rewardTotalPerSecTrader).divd(tradingVolumeTotal);
            }

            int256 _newReward = traders[_trader].periodTradingVolume.muld(accInstant - traders[_trader].accInitial);

            return traders[_trader].reward + _newReward;
        }

        /*It's the same period*/
        if (tradingVolumeTotal <= 0){
            /*no one trade yet*/
            return traders[_trader].reward;
        }
        
        
        int256 timeDiff = int256(block.timestamp - lastTradeTime);
        accInstant = accTradeTotal + timeDiff.toDecimal().muld(params.rewardTotalPerSecTrader).divd(tradingVolumeTotal);

        return traders[_trader].reward + traders[_trader].periodTradingVolume.muld(accInstant - traders[_trader].accInitial);
    }


    
    /**
     * @dev Should be called each time trader trader.
     * @param _trader address of the trader
     * @param _notional current trade position size
     **/
    function rewardTrader(address _trader, int256 _notional) external override nonReentrant onlyStripsOrOwner {
        if (startTime == 0){
            /*Setup start time for all periods once first trader ever happened*/
            startTime = block.timestamp;
            currentPeriod = 0;
        }

        int256 boostedNotional = _notional.muld(_booster(_trader));
        
        if ((block.timestamp - traders[_trader].lastTradeTime) < params.washTime && traders[_trader].isClaimed == false){
            /*If it's a wash trade just update period and return */
            _updatePeriod(boostedNotional);

            lastTradeTime = block.timestamp;
            return;
        }
        
        traders[_trader].reward = totalTradeReward(_trader);

        bool isSwitched = _updatePeriod(boostedNotional);
        if (currentPeriod != traders[_trader].lastPeriod){
            isSwitched = true;
        }

        /*Update trader */
        if (isSwitched){
            /*Reset volume */
            traders[_trader].periodTradingVolume = boostedNotional;
        }else{
            /*Accumulate trading volume for trader */
            traders[_trader].periodTradingVolume += boostedNotional;
        }

        traders[_trader].lastTradeTime = block.timestamp;
        traders[_trader].isClaimed = false;

        traders[_trader].lastPeriod = currentPeriod;
        traders[_trader].accInitial = accTradeTotal;

        lastTradeTime = block.timestamp;
    }

    /**
     * @dev Send all current reward to the trader
     **/
    function claimTradingReward(address _trader) external override {

        //Accumulate any reward till this taime
        //traders[_trader].reward = totalTradeReward(_trader).muld(params.rewardTotalPerSecTrader);
        traders[_trader].reward = totalTradeReward(_trader);

        if (traders[_trader].reward <= 0){
            return;
        }

        bool isSwitched = _updatePeriod(0);

        if (isSwitched){
            traders[_trader].periodTradingVolume = 0;
        }

        /*move accumulator */
        int256 accInstant = accTradeTotal;
        
        if (tradingVolumeTotal > 0){
            int256 timeDiff = int256(block.timestamp - lastTradeTime);
            accInstant += timeDiff.toDecimal().muld(params.rewardTotalPerSecTrader).divd(tradingVolumeTotal);
        }

        SafeERC20.safeTransferFrom(params.strpToken, 
                                    params.dao, 
                                    _trader, 
                                    uint(traders[_trader].reward));

        emit TradingRewardClaimed(
            _trader,
            traders[_trader].reward
        );


        totalTradingRewardsClaimed += traders[_trader].reward;

        /*Reset all params */
        traders[_trader].accInitial = accInstant;
        traders[_trader].lastTradeTime = block.timestamp;
        traders[_trader].isClaimed = true;
        traders[_trader].lastPeriod = currentPeriod;
        traders[_trader].reward = 0;

    }

    /**
     * @dev Calls on each actions
     * @param _notional current trade notional
     * @return isSwitched true if period switched
     **/
    function _updatePeriod(int256 _notional) internal returns (bool isSwitched) {
        isSwitched = false;

        /* _periods are not incremented by ONE.  It can be 1,2,5,8,12 Depends on when the last trade happened*/
        uint256 _period = (block.timestamp - startTime) / params.periodLength;

        /* Reset period */
        if (_period > currentPeriod){
            if (lastTradeTime != 0){
                /* Calc the rest and save */
                uint256 timeLeft = params.periodLength - (lastTradeTime - startTime) % params.periodLength;
                accPerPeriod[currentPeriod] = accTradeTotal + int256(timeLeft).toDecimal().muld(params.rewardTotalPerSecTrader).divd(tradingVolumeTotal);

                /* Reset total AMM trading volume and accumulator */
                tradingVolumeTotal = 0;
                accTradeTotal = 0;

            } //else: //It's the first trade ever, just setup period

            isSwitched = true;
            /*Switch period */
            currentPeriod = _period;

        }

        /* If it's the trade then change volume and accumulate it */
        if (_notional > 0){
            int256 timeDiff = int256(block.timestamp - lastTradeTime);
            if (lastTradeTime != 0 && tradingVolumeTotal > 0){
                // If it's not the first trade in period OR the first trade EVER
                int256 timeDiff = int256(block.timestamp - lastTradeTime);
                accTradeTotal += (timeDiff.toDecimal().muld(params.rewardTotalPerSecTrader).divd(tradingVolumeTotal));
            }
            tradingVolumeTotal += _notional;
        }
    }

    function _booster(address _trader) internal returns (int256){
        int256 supply = int256(params.slpToken.totalSupply());
        if (supply <= 0) {
            return SignedBaseMath.oneDecimal();
        }
        return SignedBaseMath.oneDecimal() + int256(params.slpToken.balanceOf(_trader)).divd(supply);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}