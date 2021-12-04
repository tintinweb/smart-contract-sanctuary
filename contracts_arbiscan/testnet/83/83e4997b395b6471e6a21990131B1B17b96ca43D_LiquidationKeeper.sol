pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import {IStrips} from "../interface/IStrips.sol";
import { SignedBaseMath } from "../lib/SignedBaseMath.sol";
import { StorageStripsLib } from "../lib/StorageStrips.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LiquidationKeeper is KeeperCompatibleInterface, AccessControl {
    using SignedBaseMath for int256;
    using Address for address;

    event LiquidatorDone(
        uint indexed length, 
        uint indexed liquidated, 
        uint indexed reverted,
        uint positionIndex
    );


    address public rewardToken;

    IStrips public strips;
    // To efficiently iterate large array of positions (hundreds),
    // Liquidation Keeper remembers the last index it processed (i.e. cursor)
    uint256 public positionIndex;
    // size specifies how many positions can be processed per single call.
    // depends on many factors and to be selected experimentally
    uint256 public size;

    constructor(IStrips _strips,
                address _rewardToken,
                uint256 _size) {
        strips = _strips;
        size = _size;
        rewardToken = _rewardToken;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev By original Chainlink Keeper specification, the keeper process calls `checkUpkeep` method
     * in order to determine if your contract requires some work to be done. Since Strips is interested
     * in the most recent data, we return `true` unconditionally. Input data gets ignored.
     * @return upkeepNeeded Indicates whether the Keeper should call performUpkeep or not.
     **/
    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory) {
        upkeepNeeded = true;
    }

    /**
     * @dev Liquidation Oracles execute the `performUpkeep` method to trigger liquidations. Calldata is ignored.
     **/
    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        uint liquidated = 0;
        uint reverted = 0;
        bool found = false;

        StorageStripsLib.PositionMeta[] memory liqPositions = strips.getPositionsForLiquidation(positionIndex, size);
        
        for (uint256 i; i < liqPositions.length; i++) {
            /*
                By default liquidatePosition will be reverted if something goes wrong OR position is not for liquidation
                BUT
                we don't want to stop loop if one of the liquidation is reverted
            */
            if (liqPositions[i].isActive){
                found = true;

                (bool success, bytes memory returndata) = address(strips).call{value: 0}(
                    abi.encodeWithSelector(strips.liquidatePosition.selector, liqPositions[i]._market, liqPositions[i]._account)
                );
                
                /*For stats */
                if (success){
                    liquidated += 1;
                }else{
                    reverted += 1;
                }
            }
        }

        // save cursor for next iteration or reset to 0 if overflow position count boundary
        if (positionIndex + size >= strips.getPositionsCount()) {
            positionIndex = 0;
        } else {
            positionIndex += size;
        }

        if (found){
            emit LiquidatorDone(
                liqPositions.length,
                liquidated,
                reverted,
                positionIndex
            );
        }

        strips.ping();
    }

    /**
     * @dev Set position index (cursor). Called by admin only.
     * @param _positionIndex new cursor position
     **/
    function setPositionIndex(uint256 _positionIndex) external onlyRole(DEFAULT_ADMIN_ROLE) {
        positionIndex = _positionIndex;
    }

    /**
     * @dev Set batch size (how many positions can be processed per call).
     * @param _size number of positions elements to process per call
     **/
    function setSize(uint256 _size) external onlyRole(DEFAULT_ADMIN_ROLE) {
        size = _size;
    }

    /**
     * @dev Change strips (proxy) address to new address
     * @param _strips new Strips address
     **/
    function setStrips(IStrips _strips) external onlyRole(DEFAULT_ADMIN_ROLE) {
        strips = _strips;
    }

    /**
     * @dev Move USDC reward for liquidation 
     * @param _to address to move funds to
     **/
    function withdrawRewards(address _to) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint balance = IERC20(rewardToken).balanceOf(address(this));
        if (balance == 0){
            return;
        }

        SafeERC20.safeTransfer(IERC20(rewardToken), 
                                    _to, 
                                    balance);
    }

    /**
     * @dev USDC by default, but can be changed 
     * @param _newToken address to move funds to
     **/
    function changeRewardToken(address _newToken) external onlyRole(DEFAULT_ADMIN_ROLE) {
        rewardToken = _newToken;
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IInsuranceFund {
    function withdraw(address _to, int256 _amount) external;

    function getLiquidity() external view returns (int256);
    function getPartedLiquidity() external view returns (int256 usdcLiquidity, int256 lpLiquidity);
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

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

interface IAssetOracle is KeeperCompatibleInterface {
    function getPrice() external view returns (int256);
    function calcOracleAverage(uint256 fromIndex) external view returns (int256);
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

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

interface IUniswapLpOracle is KeeperCompatibleInterface {
    function getPrice() external view returns (int256);
    function strpPrice() external view returns (int256);
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