// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IERC20Metadata } from "../../openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC20 } from "../../openzeppelin/token/ERC20/IERC20.sol";
import { SafeERC20 } from "../../openzeppelin/token/ERC20/utils/SafeERC20.sol";

import { DataTypes } from "../../libraries/DataTypes.sol";
import { PolyMath } from "../../libraries/PolyMath.sol";
import { Actions } from "../../libraries/opyn/Actions.sol";

import { IController } from "../../interfaces/opyn/IController.sol";
import { IWhitelist } from "../../interfaces/opyn/IWhitelist.sol";
import { IOtokenFactory } from "../../interfaces/opyn/IOtokenFactory.sol";
import { IOptionRegistry } from "../../interfaces/core/IOptionRegistry.sol";
import { IProtocol } from "./IProtocol.sol";

contract OpynImpl is IProtocol {
    using SafeERC20 for IERC20;
    using PolyMath for uint256;

    /* ============ Constants ============ */

    // Name of the implementation identifier
    string public constant _name = "Opyn-Impl-v1";

    /* ============ Immutables ============ */

    // An instance of the option factory
    IOptionRegistry public immutable optionRegistry;
    // An instance of opyn/gamma protocol controller
    IController public immutable opynController;
    // An instance of opyn whitelist
    IWhitelist public immutable opynWhitelist;
    // An instance of oToken factory
    IOtokenFactory public immutable oTokenFactory;
    // Opyn Margin Pool
    address public immutable opynMarginPool;
    // Address of USDC (asset in which strike price is denominated)
    address public immutable usdc;

    /* ============ State Variables ============ */

    // Number of Opyn Vaults opened
    uint256 public vaultCount;
    // A mapping of settlement status
    mapping(bytes32 => bool) public override hasSettled;
    // A mapping of totalCollateral
    mapping(bytes32 => uint256) public totalCollaterals;
    // A mapping of collateral payout ratio after settlement
    mapping(bytes32 => uint256) public collateralPayoutRatios;
    // A mapping of created Vaults
    mapping(bytes32 => uint256) public vaults;
    // A mapping of oToken addresses
    mapping(bytes32 => address) public oTokens;
    // A mapping of user collateral
    mapping(bytes32 => mapping(address => uint256)) public userCollaterals;

    /* ============ Events ============ */
    /**
     @notice Emitted when collateral is transferred b/w accounts
     @param data Option specification. Check DataTypes.OptionData
     @param amt Amount of collateral transferred
     @param to Receiver address
     */
    event TransferCollateral(DataTypes.OptionData data, uint256 amt, address indexed to);

    /**
     @notice Emitted when collateral is claimed after settlement
     @param data Option specification. Check DataTypes.OptionData
     @param user User address
     @param amt Amount of collateral transferred
     */
    event ClaimCollateral(DataTypes.OptionData data, address indexed user, uint256 amt);

    constructor(
        IOptionRegistry optionRegistry_,
        IController opynController_,
        IWhitelist opynWhitelist_,
        IOtokenFactory oTokenFactory_,
        address marginPool_,
        address usdc_
    ) {
        require(address(optionRegistry_) != address(0x0));
        require(address(opynController_) != address(0x0));
        require(address(opynWhitelist_) != address(0x0));
        require(address(oTokenFactory_) != address(0x0));
        require(marginPool_ != address(0x0));
        require(usdc_ != address(0x0));

        optionRegistry = optionRegistry_;
        opynController = opynController_;
        opynWhitelist = opynWhitelist_;
        oTokenFactory = oTokenFactory_;
        opynMarginPool = marginPool_;
        usdc = usdc_;
    }

    /* ============ Modifiers ============ */

    /**
     * @notice Limits a function call to option factory
     */
     modifier onlyRegistry() {
        require(msg.sender == address(optionRegistry), "OpynImpl::not-authorized");
        _;
    }

    /**
     * @notice Limits a function call to the admin of option factory
     */
    modifier onlyAdmin() {
        require(msg.sender == optionRegistry.owner(), "OpynImpl::not-authorized");
        _;
    }

    /**
     * @notice Limits a function call to root option token (polynomial option contract)
     * @param data Option specification. Check DataTypes.OptionData
     */
    modifier onlyRootToken(DataTypes.OptionData memory data) {
        bytes32 salt = keccak256(abi.encode(data.expiry, data.isCall, data.strikePrice, data.collateral, data.underlying));
        address rootToken = optionRegistry.options(salt);
        require(msg.sender == rootToken, "OpynImpl::not-authorized");
        _;
    }

    /* ============ View Methods ============ */

    // @inheritdoc IProtocol
    function name() public pure override returns (string memory) {
        return _name;
    }

    // @inheritdoc IProtocol
    function isSupported(bool isCall, address asset, address collateral) public view override returns (bool) {
        return opynWhitelist.isWhitelistedProduct(
            asset,
            usdc,
            collateral,
            !isCall
        );
    }

    // @inheritdoc IProtocol
    function getMintAmt(
        DataTypes.OptionData memory data,
        uint256 amt,
        bytes memory 
    ) public view override returns (uint256) {
        // TODO: Try converting this to MarginVault structure
        uint256 tokenUnits;

        try IERC20Metadata(data.collateral).decimals() returns (uint8 decimals) {
            tokenUnits = 10 ** decimals;
        } catch {
            tokenUnits = 10 ** 18;
        }

        if (data.isCall) {
            return tokenUnits.wmulCeil(amt);
        }

        // amt is in 18 decimals
        uint256 collateralRequired = amt.mulDiv(data.strikePrice, 10 ** 18);
        // Strike prices are in 8 decimals
        return collateralRequired.mulDivCeil(tokenUnits, 10 ** 8);
    }

    // @inheritdoc IProtocol
    function getOptionToken(DataTypes.OptionData memory data) external view override returns (address, DataTypes.TokenType) {
        bytes32 optionId = keccak256(abi.encode(data));

        return (
            oTokens[optionId],
            DataTypes.TokenType.ERC20
        );
    }

    // @inheritdoc IProtocol
    function balanceOf(DataTypes.OptionData memory data, address account) external view override returns (uint256) {
        bytes32 optionId = keccak256(abi.encode(data));
        address oToken = oTokens[optionId];

        // oTokens are 8 decimals
        uint256 scaleFactor = 10 ** 10;

        return IERC20(oToken).balanceOf(account) * scaleFactor;
    }

    // @inheritdoc IProtocol
    function collateralBalanceOf(DataTypes.OptionData memory data, address account) external view override returns (uint256) {
        bytes32 optionId = keccak256(abi.encode(data));

        return userCollaterals[optionId][account];
    }

    /* ============ Stateful Methods ============ */
    
    // @inheritdoc IProtocol
    function mint(
        DataTypes.OptionData memory data,
        uint256 amt,
        address minter,
        bytes memory
    ) external override onlyRootToken(data) returns (bool) {
        bytes32 optionId = keccak256(abi.encode(data));

        uint256 collateralRequired = getMintAmt(data, amt, "");

        IERC20 collateral = IERC20(data.collateral);

        require(collateral.balanceOf(address(this)) >= collateralRequired, "OpynImpl::insufficient-collateral");

        // Converting 18 decimals Polynomial options to 8 decimal oTokens
        uint256 mintAmt = amt / (10 ** 10);

        collateral.safeApprove(opynMarginPool, 0);
        collateral.safeApprove(opynMarginPool, collateralRequired);

        Actions.ActionArgs[] memory actions = new Actions.ActionArgs[](2);

        actions[0] = Actions.ActionArgs(
            Actions.ActionType.DepositCollateral,
            address(this),
            address(this),
            data.collateral,
            vaults[optionId],
            collateralRequired,
            0,
            ""
        );

        actions[0] = Actions.ActionArgs(
            Actions.ActionType.MintShortOption,
            address(this),
            address(this),
            oTokens[optionId],
            vaults[optionId],
            mintAmt,
            0,
            ""
        );

        opynController.operate(actions);

        userCollaterals[optionId][minter] += amt;
        totalCollaterals[optionId] += collateralRequired;

        IERC20 oToken = IERC20(oTokens[optionId]);

        oToken.safeTransfer(msg.sender, mintAmt);

        return true;
    }

    // @inheritdoc IProtocol
    function redeem(
        DataTypes.OptionData memory data,
        uint256 amt,
        address user,
        bytes memory 
    ) external override onlyRootToken(data) returns (bool) {
        bytes32 optionId = keccak256(abi.encode(data));

        require(userCollaterals[optionId][user] >= amt, "OpynImpl::insufficient-amt");

        uint256 collateralRequired = getMintAmt(data, amt, "");

        IERC20 collateral = IERC20(data.collateral);
        IERC20 oToken = IERC20(oTokens[optionId]);

        uint256 optionAmt = amt / (10 ** 10);

        oToken.safeTransferFrom(msg.sender, address(this), optionAmt);

        Actions.ActionArgs[] memory actions = new Actions.ActionArgs[](2);

        actions[0] = Actions.ActionArgs(
            Actions.ActionType.BurnShortOption,
            address(this),
            address(this),
            address(oToken),
            vaults[optionId],
            optionAmt,
            0,
            ""
        );

        actions[1] = Actions.ActionArgs(
            Actions.ActionType.WithdrawCollateral,
            address(this),
            address(this),
            data.collateral,
            vaults[optionId],
            collateralRequired,
            0,
            ""
        );

        opynController.operate(actions);

        collateral.safeTransfer(user, collateralRequired);

        userCollaterals[optionId][user] -= amt;
        totalCollaterals[optionId] -= collateralRequired;

        return true;
    }

    // @inheritdoc IProtocol
    function settle(
        DataTypes.OptionData memory data
    ) external override onlyRootToken(data) returns (bool, uint256) {
        bytes32 optionId = keccak256(abi.encode(data));

        IERC20 collateral = IERC20(data.collateral);
        IERC20 oToken = IERC20(oTokens[optionId]);

        uint256 oTokenBal = oToken.balanceOf(msg.sender);
        oToken.safeTransferFrom(msg.sender, address(this), oTokenBal);

        uint256 preSettleBal = collateral.balanceOf(msg.sender);
        uint256 preSettleCollBal = collateral.balanceOf(address(this));
        Actions.ActionArgs[] memory actions = new Actions.ActionArgs[](2);
        actions[0] = Actions.ActionArgs(
            Actions.ActionType.Redeem,
            address(0x0),
            msg.sender,
            address(oToken),
            0,
            oTokenBal,
            0,
            ""
        );
        actions[1] = Actions.ActionArgs(
            Actions.ActionType.SettleVault,
            address(this),
            address(this),
            address(0x0),
            vaults[optionId],
            0,
            0,
            ""
        );
        opynController.operate(actions);
        uint256 postSettleBal = collateral.balanceOf(msg.sender);
        uint256 postSettleCollBal = collateral.balanceOf(address(this));

        uint256 payout = postSettleBal - preSettleBal;
        uint256 collateralReturned = postSettleCollBal - preSettleCollBal;

        hasSettled[optionId] = true;
        collateralPayoutRatios[optionId] = collateralReturned.wdiv(totalCollaterals[optionId]);

        return (true, payout);
    }

    // @inheritdoc IProtocol
    function claimCollateral(
        DataTypes.OptionData memory data
    ) external override returns (bool) {
        return _claimCollateral(data, msg.sender);
    }

    // @inheritdoc IProtocol
    function claimCollateral(
        DataTypes.OptionData memory data,
        address user
    ) external override onlyRootToken(data) returns (bool) {
        return _claimCollateral(data, user);
    }

    // @inheritdoc IProtocol
    function transferCollateral(
        DataTypes.OptionData memory data,
        uint256 amt,
        address to
    ) external override returns (bool) {
        bytes32 optionId = keccak256(abi.encode(data));

        require(userCollaterals[optionId][msg.sender] >= amt, "OpynImpl::insufficient-amt");

        userCollaterals[optionId][msg.sender] -= amt;
        userCollaterals[optionId][to] += amt;

        emit TransferCollateral(data, amt, to);

        return true;
    }

    // @inheritdoc IProtocol
    function create(
        DataTypes.Option memory data
    ) external override onlyRegistry returns (bool) {
        vaultCount += 1;

        Actions.ActionArgs[] memory actions = new Actions.ActionArgs[](1);
        Actions.ActionArgs memory action = Actions.ActionArgs(
            Actions.ActionType.OpenVault,
            address(this),
            address(this),
            address(0x0),
            vaultCount,
            0,
            0,
            ""
        );
        actions[0] = action;
        opynController.operate(actions);

        DataTypes.OptionData memory optionData = DataTypes.OptionData(
            data.expiry,
            data.isCall,
            data.strikePrice,
            data.collateral,
            data.underlying
        );

        bytes32 optionId = keccak256(abi.encode(optionData));
        vaults[optionId] = vaultCount;

        address oToken = oTokenFactory.getOtoken(
            data.underlying,
            usdc,
            data.collateral,
            data.strikePrice,
            uint256(data.expiry),
            !data.isCall
        );

        if (oToken == address(0x0)) {
            oToken = oTokenFactory.createOtoken(
                data.underlying,
                usdc,
                data.collateral,
                data.strikePrice,
                uint256(data.expiry),
                !data.isCall
            );
        }

        oTokens[optionId] = oToken;

        return true;
    }

    function _claimCollateral(
        DataTypes.OptionData memory data,
        address user
    ) internal returns(bool) {
        bytes32 optionId = keccak256(abi.encode(data));

        require(hasSettled[optionId], "UMAImpl::settlement-pending");

        uint256 amt = userCollaterals[optionId][user];
        userCollaterals[optionId][user] = 0;
        uint256 mintAmt = getMintAmt(data, amt, "");
        uint256 amtToReturn = mintAmt.wmul(collateralPayoutRatios[optionId]);

        IERC20(data.collateral).safeTransfer(user, amtToReturn);

        emit ClaimCollateral(data, user, amtToReturn);

        return true;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library DataTypes {
    struct Asset {
        bool isActive;
        string name;
        string symbol;
    }

    struct Option {
        uint64 expiry;
        bool isCall;
        uint256 strikePrice;
        address collateral;
        address underlying;
        address[] impls;
    }

    struct OptionData {
        uint64 expiry;
        bool isCall;
        uint256 strikePrice;
        address collateral;
        address underlying;
    }

    enum TokenType {
        ERC20,
        ERC721,
        ERC1155,
        None
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library PolyMath {
    function mulDiv(uint256 a, uint256 b, uint256 c) internal pure returns (uint256 d) {
        d = a * b / c;
    }

    function mulDivCeil(uint256 a, uint256 b, uint256 c) internal pure returns (uint256 d) {
        d = mulDiv(a, b, c);
        uint256 mod = (a * b) % c;
        if (mod > 0) {
            d++;
        }
    }

    function wmul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = mulDiv(a, b, 10 ** 18);
    }

    function wmulCeil(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = mulDivCeil(a, b, 10 ** 18);
    }

    function wdiv(uint256 a, uint b) internal pure returns (uint256 c) {
        c = a * (10 ** 18) / b;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

library Actions {
    // possible actions that can be performed
    enum ActionType {
        OpenVault,
        MintShortOption,
        BurnShortOption,
        DepositLongOption,
        WithdrawLongOption,
        DepositCollateral,
        WithdrawCollateral,
        SettleVault,
        Redeem,
        Call,
        Liquidate
    }

    struct ActionArgs {
        // type of action that is being performed on the system
        ActionType actionType;
        // address of the account owner
        address owner;
        // address which we move assets from or to (depending on the action type)
        address secondAddress;
        // asset that is to be transfered
        address asset;
        // index of the vault that is to be modified (if any)
        uint256 vaultId;
        // amount of asset that is to be transfered
        uint256 amount;
        // each vault can hold multiple short / long / collateral assets but we are restricting the scope to only 1 of each in this version
        // in future versions this would be the index of the short / long / collateral asset that needs to be modified
        uint256 index;
        // any other data that needs to be passed in for arbitrary function calls
        bytes data;
    }

    struct MintArgs {
        // address of the account owner
        address owner;
        // index of the vault from which the asset will be minted
        uint256 vaultId;
        // address to which we transfer the minted oTokens
        address to;
        // oToken that is to be minted
        address otoken;
        // each vault can hold multiple short / long / collateral assets but we are restricting the scope to only 1 of each in this version
        // in future versions this would be the index of the short / long / collateral asset that needs to be modified
        uint256 index;
        // amount of oTokens that is to be minted
        uint256 amount;
    }

    struct BurnArgs {
        // address of the account owner
        address owner;
        // index of the vault from which the oToken will be burned
        uint256 vaultId;
        // address from which we transfer the oTokens
        address from;
        // oToken that is to be burned
        address otoken;
        // each vault can hold multiple short / long / collateral assets but we are restricting the scope to only 1 of each in this version
        // in future versions this would be the index of the short / long / collateral asset that needs to be modified
        uint256 index;
        // amount of oTokens that is to be burned
        uint256 amount;
    }

    struct OpenVaultArgs {
        // address of the account owner
        address owner;
        // vault id to create
        uint256 vaultId;
        // vault type, 0 for spread/max loss and 1 for naked margin vault
        uint256 vaultType;
    }

    struct DepositArgs {
        // address of the account owner
        address owner;
        // index of the vault to which the asset will be added
        uint256 vaultId;
        // address from which we transfer the asset
        address from;
        // asset that is to be deposited
        address asset;
        // each vault can hold multiple short / long / collateral assets but we are restricting the scope to only 1 of each in this version
        // in future versions this would be the index of the short / long / collateral asset that needs to be modified
        uint256 index;
        // amount of asset that is to be deposited
        uint256 amount;
    }

    struct RedeemArgs {
        // address to which we pay out the oToken proceeds
        address receiver;
        // oToken that is to be redeemed
        address otoken;
        // amount of oTokens that is to be redeemed
        uint256 amount;
    }

    struct WithdrawArgs {
        // address of the account owner
        address owner;
        // index of the vault from which the asset will be withdrawn
        uint256 vaultId;
        // address to which we transfer the asset
        address to;
        // asset that is to be withdrawn
        address asset;
        // each vault can hold multiple short / long / collateral assets but we are restricting the scope to only 1 of each in this version
        // in future versions this would be the index of the short / long / collateral asset that needs to be modified
        uint256 index;
        // amount of asset that is to be withdrawn
        uint256 amount;
    }

    struct SettleVaultArgs {
        // address of the account owner
        address owner;
        // index of the vault to which is to be settled
        uint256 vaultId;
        // address to which we transfer the remaining collateral
        address to;
    }

    struct LiquidateArgs {
        // address of the vault owner to liquidate
        address owner;
        // address of the liquidated collateral receiver
        address receiver;
        // vault id to liquidate
        uint256 vaultId;
        // amount of debt(otoken) to repay
        uint256 amount;
        // chainlink round id
        uint256 roundId;
    }

    struct CallArgs {
        // address of the callee contract
        address callee;
        // data field for external calls
        bytes data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { Actions } from "../../libraries/opyn/Actions.sol";

interface IController {
    function operate(Actions.ActionArgs[] memory actions) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IWhitelist {
    function isWhitelistedProduct(
        address underlying,
        address strike,
        address collateral,
        bool isPut
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IOtokenFactory {
    function getOtoken(
        address underlyingAsset,
        address strikeAsset,
        address collateralAsset,
        uint256 strikePrice,
        uint256 expiry,
        bool isPut
    ) external view returns (address);

    function createOtoken(
        address underlyingAsset,
        address strikeAsset,
        address collateralAsset,
        uint256 strikePrice,
        uint256 expiry,
        bool isPut
    ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { DataTypes } from "../../libraries/DataTypes.sol";

interface IOptionRegistry {
    function implementations(address) external view returns (bool);

    function assets(address) external view returns (DataTypes.Asset memory);

    function owner() external view returns (address);

    function options(bytes32) external view returns (address);

    function isOption(address) external view returns (bool);

    function optionTokenLogic() external view returns (address);

    function createSeries(DataTypes.Option memory) external returns (address);

    function addImplementation(address impl) external;

    function removeImplementation(address impl) external;

    function approveAsset(address asset, string memory name, string memory symbol) external;

    function removeAsset(address asset) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { DataTypes } from "../../libraries/DataTypes.sol";

interface IProtocol {

    /**
     * @notice Name of the implementation
     */
    function name() external view returns (string memory _name);

    /**
     * @notice This method checks whether the underlying protocol can mint options of the mentioned specs
     * @param isCall Whether the option is a call option
     * @param asset Address of the underlying asset
     * @param collateral Address of the collateral asset (if put option => asset ≠ collateral)
     */
    function isSupported(bool isCall, address asset, address collateral) external view returns (bool _isSupported);

    /**
     * @notice Returns whether the options have been settled from the protocol
     * @param id Option id/hash
     * @return _hasSettled Status of the settlement
     */
    function hasSettled(bytes32 id) external view returns (bool _hasSettled);

    /**
     * @notice This method calculates the amount of collateral required to mint a specified number of options
     * @param data Option specification. Check DataTypes.OptionData
     * @param amt Amount of options being minted
     * @param mintData Additional mint data being passed to the protocol
     * @return _collateralNeeded Amount of collateral needed to mint the option
     */
    function getMintAmt(
        DataTypes.OptionData memory data,
        uint256 amt,
        bytes memory mintData
    ) external view returns (uint256 _collateralNeeded);

    /**
     * @notice Returns the address of the option token used by the protocol, if any
     * @param data Option specification. Check DataTypes.OptionData
     * @return _subOption Address of the option token used by the protocol, 0x0 if the protocol doesn't use any token
     * @return _type The type of token standard
     */
    function getOptionToken(DataTypes.OptionData memory data) external view returns (address _subOption, DataTypes.TokenType _type);

    /**
     * @notice Returns the amount of (sub)options held by an account. After taking care of protocols which doesn't use tokens to account
     * @param data Option specification. Check DataTypes.OptionData
     * @param account Address of the account to check
     * @return _bal Amount of options held by the account
     */
    function balanceOf(DataTypes.OptionData memory data, address account) external view returns (uint256 _bal);

    /**
     * @notice Returns the maximum amount of collateral that can be claimed by an account. After taking care of protocols which doesn't use tokens to account
     * @param data Option specification. Check DataTypes.OptionData
     * @param account Address of the account to check
     * @return _bal Amount of collateral claimed by the account
     */
    function collateralBalanceOf(DataTypes.OptionData memory data, address account) external view returns (uint256 _bal);
    
    /**
     * @notice Mint (sub)options and transfer to polynomial option, if any
     * @param data Option specification. Check DataTypes.OptionData
     * @param amt Amount of options being minted
     * @param minter Address of the minter
     * @param mintData Additional mint data being passed to the protocol
     * @return _hasCreated Returns whether the action was successful
     */
    function mint(
        DataTypes.OptionData memory data,
        uint256 amt,
        address minter,
        bytes memory mintData
    ) external returns (bool _hasCreated);

    /**
     * @notice Redeem collateral before expiry
     * @param data Option specification. Check DataTypes.OptionData
     * @param amt Amount of options to redeem
     * @param user Address of the account that is redeeming the tokens
     * @param redeemData Additional redeem data being passed to the protocol
     * @return _hasRedeemed Returns whether the action was successful
     */
    function redeem(
        DataTypes.OptionData memory data,
        uint256 amt,
        address user,
        bytes memory redeemData
    ) external returns (bool _hasRedeemed);

    /**
     * @notice Settle options and collateral after expiry + 6 hours
     * @param data Option specification. Check DataTypes.OptionData
     * @return _hasSettled Returns whether the action was successful
     */
    function settle(
        DataTypes.OptionData memory data
    ) external returns (bool _hasSettled, uint256 _returnedAmt);

    /**
     * @notice Claim collateral after settlement is completed
     * @param data Option specification. Check DataTypes.OptionData
     * @return _isSuccess Returns whether the action was successful
     */
    function claimCollateral(
        DataTypes.OptionData memory data
    ) external returns (bool _isSuccess);

    /**
     * @notice Claim collateral after settlement is completed (called by rootToken)
     * @param data Option specification. Check DataTypes.OptionData
     * @param user Address of the user
     * @return _isSuccess Returns whether the action was successful
     */
    function claimCollateral(
        DataTypes.OptionData memory data,
        address user
    ) external returns (bool _isSuccess);

    /**
     * @notice Transfer collateral
     * @param data Option specification. Check DataTypes.OptionData
     * @param amt Amount of collateral to transfer
     * @param to Target account
     * @return _isSuccess Returns whether the action was successful
     */
    function transferCollateral(
        DataTypes.OptionData memory data,
        uint256 amt,
        address to
    ) external returns (bool _isSuccess);

    /**
     * @notice Create a (sub)option token if it is required by the protocol. Can be ignored for some protocols. Only called by optionRegistry
     * @param data Option specification. Check DataTypes.OptionData
     * @return _isSuccess Returns whether the action was successful
     */
    function create(
        DataTypes.Option memory data
    ) external returns (bool _isSuccess);
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