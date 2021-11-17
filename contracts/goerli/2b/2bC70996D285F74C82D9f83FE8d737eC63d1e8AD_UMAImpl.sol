// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IERC20Metadata } from "../../openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC20 } from "../../openzeppelin/token/ERC20/IERC20.sol";
import { SafeERC20 } from "../../openzeppelin/token/ERC20/utils/SafeERC20.sol";

import { ILongShortPairCreator } from "../../interfaces/UMA/ILongShortPairCreator.sol";
import { ILongShortPair } from "../../interfaces/UMA/ILongShortPair.sol";
import { ICoveredCallFinancialLibrary } from "../../interfaces/UMA/ICoveredCallFinancialLibrary.sol";

import { DataTypes } from "../../libraries/DataTypes.sol";
import { PolyMath } from "../../libraries/PolyMath.sol";
import { FixedPoint } from "../../libraries/UMA/FixedPoint.sol";

import { IOptionRegistry } from "../../interfaces/core/IOptionRegistry.sol";
import { IProtocol } from "./IProtocol.sol";

contract UMAImpl is IProtocol {
    using FixedPoint for FixedPoint.Unsigned;
    using SafeERC20 for IERC20;
    using PolyMath for uint256;
    
    /* ============ Constants ============ */

    // Name of the implementation identifier
    string private constant _name = "UMA-Impl-v1";

    /* ============ Immutables ============ */

    // An instance of Long-Short pair to create new Long-Short Pair Tokens
    ILongShortPairCreator public immutable lspCreator;
    // An instance of UMA Covered Call Financial Product Library
    ICoveredCallFinancialLibrary public immutable coveredCallLibrary;
    // An instance of the option factory
    IOptionRegistry public immutable optionRegistry;

    /* ============ State Variables ============ */

    // A mapping of settlement status
    mapping(bytes32 => bool) public override hasSettled;
    // A mapping of totalCollateral
    mapping(bytes32 => uint256) public totalCollaterals;
    // A mapping of collateral payout ratio after settlement
    mapping(bytes32 => uint256) public collateralPayoutRatios;
    // A mapping of price identifiers
    mapping(address => bytes32) public priceIds;
    // A mapping of created LSPs
    mapping(bytes32 => address) public lsps;
    // A mapping of user-held short tokens
    mapping(bytes32 => mapping(address => uint256)) public shortTokenAmts;

    /* ============ Events ============ */

    /**
     @notice Emitted when price id of the collateral is updated
     @param collateral Address of the collateral
     @param id New ID of the collateral
     */
    event UpdatePriceID(address indexed collateral, bytes32 indexed id);

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

    /**
     * @notice Contract initialization
     * @param lspCreator_ The address of UMA Long-Short Pair Creator
     * @param coveredCall_ The address of UMA Covered Call Financial Product Library
     * @param optionRegistry_ The address of Option Registry
     */
    constructor(ILongShortPairCreator lspCreator_, ICoveredCallFinancialLibrary coveredCall_, IOptionRegistry optionRegistry_) {
        require(address(optionRegistry_) != address(0x0), "UMAImpl::zero-addr");
        require(address(lspCreator_) != address(0x0), "UMAImpl::zero-addr");
        require(address(coveredCall_) != address(0x0), "UMAImpl::zero-addr");

        lspCreator = lspCreator_;
        coveredCallLibrary = coveredCall_;
        optionRegistry = optionRegistry_;
    }

    /* ============ Modifiers ============ */

    /**
     * @notice Limits a function call to the admin of option factory
     */
    modifier onlyAdmin() {
        require(msg.sender == optionRegistry.owner(), "UMAImpl::not-authorized");
        _;
    }

    modifier onlyCallOption(DataTypes.OptionData memory data) {
        require(data.isCall && data.collateral == data.underlying, "UMAImpl::only-call-options");
        _;
    }

    /**
     * @notice Limits a function call to root option token (polynomial option contract)
     * @param data Option specification. Check DataTypes.OptionData
     */
    modifier onlyRootToken(DataTypes.OptionData memory data) {
        bytes32 salt = keccak256(abi.encode(data.expiry, data.isCall, data.strikePrice, data.collateral, data.underlying));
        address rootToken = optionRegistry.options(salt);
        require(msg.sender == rootToken, "UMAImpl::not-authorized");
        _;
    }

    /**
     * @notice Limits a function call to root option token (polynomial option contract)
     * @param data Option specification. Check DataTypes.Option
     */
    modifier onlyOptionToken(DataTypes.Option memory data) {
        (address rootToken, ) = optionRegistry.getOptionAddress(data);
        require(msg.sender == rootToken, "UMAImpl::not-authorized");
        _;
    }

    /* ============ View Methods ============ */

    // @inheritdoc IProtocol
    function name() public pure override returns (string memory) {
        return _name;
    }

    // @inheritdoc IProtocol
    function isSupported(bool isCall, address asset, address collateral) public view override returns (bool) {
        if (isCall && asset == collateral) {
            (bool isActive, ,) = optionRegistry.assets(collateral);
            return isActive;
        }
        return false;
    }

    // @inheritdoc IProtocol
    function getMintAmt(
        DataTypes.OptionData memory data,
        uint256 amt,
        bytes memory 
    ) public view override returns (uint256) {
        if (data.isCall && data.collateral == data.underlying) {
            // Same logic as UMA LSP contract
            bytes32 lspKey = keccak256(abi.encode(data));
            uint256 collateralPerPair = ILongShortPair(lsps[lspKey]).collateralPerPair();
            uint256 collateralUsed = FixedPoint.Unsigned(amt).mulCeil(FixedPoint.Unsigned(collateralPerPair)).rawValue;
            return collateralUsed;
        }
        return type(uint256).max;
    }

    // @inheritdoc IProtocol
    function getOptionToken(DataTypes.OptionData memory data) external view override returns (address, DataTypes.TokenType) {
        if (data.isCall && data.collateral == data.underlying) {
            bytes32 lspKey = keccak256(abi.encode(data));
            ILongShortPair lsp = ILongShortPair(lsps[lspKey]);

            address longToken = lsp.longToken();

            return (longToken, DataTypes.TokenType.ERC20);
        }
        return (address(0x0), DataTypes.TokenType.None);
    }

    // @inheritdoc IProtocol
    function balanceOf(DataTypes.OptionData memory data, address account) external view override returns (uint256) {
        if (data.isCall && data.collateral == data.underlying) {
            bytes32 lspKey = keccak256(abi.encode(data));
            ILongShortPair lsp = ILongShortPair(lsps[lspKey]);

            IERC20 longToken = IERC20(lsp.longToken());

            return longToken.balanceOf(account);
        }
        return 0;
    }

    // @inheritdoc IProtocol
    function collateralBalanceOf(DataTypes.OptionData memory data, address account) external view override returns (uint256) {
        if (data.isCall && data.collateral == data.underlying) {
            bytes32 lspKey = keccak256(abi.encode(data));

            return shortTokenAmts[lspKey][account];
        }
        return 0;
    }

    /* ============ Stateful Methods ============ */
    
    // @inheritdoc IProtocol
    function mint(
        DataTypes.OptionData memory data,
        uint256 amt,
        address minter,
        bytes memory mintData
    ) external override onlyRootToken(data) onlyCallOption(data) returns (bool) {
        // Get the amount of collateral required to mint `amt` of options
        uint256 mintAmt = getMintAmt(data, amt, mintData);

        // Checks whether the collateral has been received from rootToken
        IERC20 collateral = IERC20(data.collateral);
        require(collateral.balanceOf(address(this)) >= mintAmt, "UMAImpl::coll-not-received");

        bytes32 lspKey = keccak256(abi.encode(data));
        ILongShortPair lsp = ILongShortPair(lsps[lspKey]);

        // Mint both long and short tokens from UMA
        collateral.safeApprove(address(lsp), mintAmt);
        lsp.create(amt);

        // Transfer the long tokens back to root token
        IERC20 longToken = IERC20(lsp.longToken());
        longToken.safeTransfer(msg.sender, amt);

        // Assign the short tokens to minter
        shortTokenAmts[lspKey][minter] += amt;
        totalCollaterals[lspKey] += mintAmt;

        return true;
    }

    // @inheritdoc IProtocol
    function redeem(
        DataTypes.OptionData memory data,
        uint256 amt,
        address user,
        bytes memory 
    ) external override onlyRootToken(data) onlyCallOption(data) returns (bool) {
        // Get LSP
        bytes32 lspKey = keccak256(abi.encode(data));
        ILongShortPair lsp = ILongShortPair(lsps[lspKey]);

        // Get the user collateral (short token) balance registered on the contract
        uint256 shortTokenBal = shortTokenAmts[lspKey][user];
        require(shortTokenBal >= amt, "UMAImpl::missing-long-tokens");

        // Get the options from Root Token
        IERC20(lsp.longToken()).safeTransferFrom(msg.sender, address(this), amt);

        // Execute redeem on UMA
        uint256 collateralReturned = lsp.redeem(amt);
        shortTokenAmts[lspKey][user] -= amt;
        totalCollaterals[lspKey] -= collateralReturned;

        // Return the collateral
        IERC20(data.collateral).safeTransfer(user, collateralReturned);

        return true;
    }

    // @inheritdoc IProtocol
    function settle(
        DataTypes.OptionData memory data
    ) external override onlyRootToken(data) onlyCallOption(data) returns (bool, uint256) {
        // Get LSP
        bytes32 lspKey = keccak256(abi.encode(data));
        ILongShortPair lsp = ILongShortPair(lsps[lspKey]);

        // Settle long tokens (options) alone
        IERC20 longToken = IERC20(lsp.longToken());
        uint256 longTokenBal = longToken.balanceOf(msg.sender);
        longToken.safeTransferFrom(msg.sender, address(this), longTokenBal);
        uint256 payout = lsp.settle(longTokenBal, 0);

        {
            // Settle all short tokens (collateral) alone & calculate the payout ratio
            IERC20 shortToken = IERC20(lsp.shortToken());
            uint256 shortTokenBal = shortToken.balanceOf(address(this));
            uint256 collateralReturned = lsp.settle(0, shortTokenBal);
            collateralPayoutRatios[lspKey] = totalCollaterals[lspKey] > 0 ? collateralReturned.wdiv(totalCollaterals[lspKey]) : 0;
        }

        hasSettled[lspKey] = true;

        IERC20(data.collateral).safeTransfer(msg.sender, payout);

        return (true, payout);
    }

    // @inheritdoc IProtocol
    function claimCollateral(
        DataTypes.OptionData memory data
    ) external override onlyCallOption(data) returns (bool) {
        bytes32 lspKey = keccak256(abi.encode(data));
        uint256 shortTokenBal = shortTokenAmts[lspKey][msg.sender];
        require(shortTokenBal > 0, "UMAImpl::no-coll");
        return _claimCollateral(data, msg.sender);
    }

    // @inheritdoc IProtocol
    function claimCollateral(
        DataTypes.OptionData memory data,
        address user
    ) external override onlyRootToken(data) onlyCallOption(data) returns (bool) {
        return _claimCollateral(data, user);
    }

    // @inheritdoc IProtocol
    function transferCollateral(
        DataTypes.OptionData memory data,
        uint256 amt,
        address to
    ) external override returns (bool) {
        // Get LSP Key
        bytes32 lspKey = keccak256(abi.encode(data));

        // Get the user collateral (short token) balance registered on the contract
        uint256 shortTokenBal = shortTokenAmts[lspKey][msg.sender];

        require(shortTokenBal >= amt, "UMAImpl::insufficient-collateral");

        shortTokenAmts[lspKey][msg.sender] -= amt;
        shortTokenAmts[lspKey][to] += amt;

        emit TransferCollateral(data, amt, to);

        return true;
    }

    // @inheritdoc IProtocol
    function create(
        DataTypes.Option memory data
    ) external override onlyOptionToken(data) returns (bool) {
        require(data.isCall && data.underlying == data.collateral, "UMAImpl::only-call-options");

        uint256 tokenUnits;
        try IERC20Metadata(data.collateral).decimals() returns (uint8 decimals) {
            tokenUnits = 10 ** decimals;
        } catch {
            tokenUnits = 10 ** 18;
        }

        // TODO: Name option tokens without causing stack too deep
        // TODO: Create names for both long and short tokens
        // (, string memory assetName, string memory assetSymbol) = optionRegistry.assets(data.collateral);

        // string memory syntheticName = string(abi.encodePacked(assetName, " Call Option"));
        // string memory syntheticSymbol = string(abi.encodePacked("o", assetSymbol, "-C"));

        // Create LSP
        address lsp = lspCreator.createLongShortPair(
            data.expiry,
            tokenUnits,
            priceIds[data.collateral],
            "Polynomial Option",
            "p-Option",
            data.collateral,
            address(coveredCallLibrary),
            bytes(""),
            0
        );

        // Set strike price
        coveredCallLibrary.setLongShortPairParameters(lsp, data.strikePrice);

        DataTypes.OptionData memory optionData = DataTypes.OptionData(
            data.expiry,
            data.isCall,
            data.strikePrice,
            data.collateral,
            data.underlying
        );

        bytes32 lspKey = keccak256(abi.encode(optionData));
        lsps[lspKey] = lsp;

        return true;
    }

    /**
     * @notice Assign and update price ID for collateral (for UMA settlement)
     * @param collateral Address of the collateral
     * @param id Price ID of the collateral
     */
    function updatePriceId(address collateral, bytes32 id) external onlyAdmin {
        // DataTypes.Asset memory asset = optionRegistry.assets(collateral);
        (bool isActive, ,) = optionRegistry.assets(collateral);
        require(isActive, "UMAImpl::invalid-collateral");

        priceIds[collateral] = id;

        emit UpdatePriceID(collateral, id);
    }

    function _claimCollateral(
        DataTypes.OptionData memory data,
        address user
    ) internal returns(bool) {
        bytes32 lspKey = keccak256(abi.encode(data));

        require(hasSettled[lspKey], "UMAImpl::settlement-pending");

        // Collect collateral based on the payout ratio
        uint256 amt = shortTokenAmts[lspKey][user];
        shortTokenAmts[lspKey][user] = 0;
        uint256 mintAmt = getMintAmt(data, amt, "");
        uint256 amtToReturn = mintAmt.wmul(collateralPayoutRatios[lspKey]);

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

interface ILongShortPairCreator {
    /**
     * @notice Creates a longShortPair contract and associated long and short tokens.
     * @dev The caller must approve this contract to transfer `prepaidProposerReward` amount of collateral.
     * @param expirationTimestamp unix timestamp of when the contract will expire.
     * @param collateralPerPair how many units of collateral are required to mint one pair of synthetic tokens.
     * @param priceIdentifier registered in the DVM for the synthetic.
     * @param syntheticName Name of the synthetic tokens to be created. The long tokens will have "Long Token" appended
     *     to the end and the short token will "Short Token" appended to the end to distinguish within the LSP's tokens.
     * @param syntheticSymbol Symbol of the synthetic tokens to be created. The long tokens will have "l" prepended
     *     to the start and the short token will "s" prepended to the start to distinguish within the LSP's tokens.
     * @param collateralToken ERC20 token used as collateral in the LSP.
     * @param financialProductLibrary Contract providing settlement payout logic.
     * @param customAncillaryData Custom ancillary data to be passed along with the price request. If not needed, this
     *                             should be left as a 0-length bytes array.
     * @param prepaidProposerReward Proposal reward forwarded to the created LSP to incentivize price proposals.
     * @return lspAddress the deployed address of the new long short pair contract.
     * @notice The created LSP is NOT registered within the registry as the LSP contract uses the DVM.
     * @notice The LSP constructor does a number of validations on input params. These are not repeated here.
     */
    function createLongShortPair(
        uint64 expirationTimestamp,
        uint256 collateralPerPair,
        bytes32 priceIdentifier,
        string memory syntheticName,
        string memory syntheticSymbol,
        address collateralToken,
        address financialProductLibrary,
        bytes memory customAncillaryData,
        uint256 prepaidProposerReward
    ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ILongShortPair {
    function longToken() external view returns (address);
    
    function shortToken() external view returns (address);

    function collateralToken() external view returns (address);

    function expirationTimestamp() external view returns (uint64);

    function collateralPerPair() external view returns (uint256);

    function create(uint256 tokensToCreate) external returns (uint256);

    function redeem(uint256 tokensToRedeem) external returns (uint256);

    function settle(uint256 longTokensToRedeem, uint256 shortTokensToRedeem) external returns (uint256);

    function expire() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICoveredCallFinancialLibrary {
    function setLongShortPairParameters(address longShortPair, uint256 strikePrice) external;

    function longShortPairStrikePrices(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library DataTypes {
    // Asset specification
    struct Asset {
        bool isActive; // Whether the asset is active or not
        string name; // Name of the asset
        string symbol; // Symbol of the asset
    }

    // Option specification with implementations
    struct Option {
        uint64 expiry; // Expiry timestamp of the option
        bool isCall; // Whether the option is call or put
        uint256 strikePrice; // Strike price in 8 decimals
        address collateral; // Address of the collateral
        address underlying; // Address of the underlying
        address[] impls; // Array of valid implementations
    }

    // Option specification
    struct OptionData {
        uint64 expiry; // Expiry timestamp of the option
        bool isCall; // Whether the option is call or put
        uint256 strikePrice; // Strike price in 8 decimals
        address collateral; // Address of the collateral
        address underlying; // Address of the underlying
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

import "../../openzeppelin/utils/math/SafeMath.sol";
import "../../openzeppelin/utils/math/SignedSafeMath.sol";

/**
 * @title Library for fixed point arithmetic on uints
 */
library FixedPoint {
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    // Supports 18 decimals. E.g., 1e18 represents "1", 5e17 represents "0.5".
    // For unsigned values:
    //   This can represent a value up to (2^256 - 1)/10^18 = ~10^59. 10^59 will be stored internally as uint256 10^77.
    uint256 private constant FP_SCALING_FACTOR = 10**18;

    // --------------------------------------- UNSIGNED -----------------------------------------------------------------------------
    struct Unsigned {
        uint256 rawValue;
    }

    /**
     * @notice Constructs an `Unsigned` from an unscaled uint, e.g., `b=5` gets stored internally as `5*(10**18)`.
     * @param a uint to convert into a FixedPoint.
     * @return the converted FixedPoint.
     */
    function fromUnscaledUint(uint256 a) internal pure returns (Unsigned memory) {
        return Unsigned(a.mul(FP_SCALING_FACTOR));
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if equal, or False.
     */
    function isEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue == fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if equal, or False.
     */
    function isEqual(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue == b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue > fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue >= fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue < fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a < b`, or False.
     */
    function isLessThan(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue <= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue <= fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue <= b.rawValue;
    }

    /**
     * @notice The minimum of `a` and `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the minimum of `a` and `b`.
     */
    function min(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return a.rawValue < b.rawValue ? a : b;
    }

    /**
     * @notice The maximum of `a` and `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the maximum of `a` and `b`.
     */
    function max(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return a.rawValue > b.rawValue ? a : b;
    }

    /**
     * @notice Adds two `Unsigned`s, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the sum of `a` and `b`.
     */
    function add(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.add(b.rawValue));
    }

    /**
     * @notice Adds an `Unsigned` to an unscaled uint, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the sum of `a` and `b`.
     */
    function add(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return add(a, fromUnscaledUint(b));
    }

    /**
     * @notice Subtracts two `Unsigned`s, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the difference of `a` and `b`.
     */
    function sub(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.sub(b.rawValue));
    }

    /**
     * @notice Subtracts an unscaled uint256 from an `Unsigned`, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the difference of `a` and `b`.
     */
    function sub(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return sub(a, fromUnscaledUint(b));
    }

    /**
     * @notice Subtracts an `Unsigned` from an unscaled uint256, reverting on overflow.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return the difference of `a` and `b`.
     */
    function sub(uint256 a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return sub(fromUnscaledUint(a), b);
    }

    /**
     * @notice Multiplies two `Unsigned`s, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mul(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        // There are two caveats with this computation:
        // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
        // stored internally as a uint256 ~10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
        // would round to 3, but this computation produces the result 2.
        // No need to use SafeMath because FP_SCALING_FACTOR != 0.
        return Unsigned(a.rawValue.mul(b.rawValue) / FP_SCALING_FACTOR);
    }

    /**
     * @notice Multiplies an `Unsigned` and an unscaled uint256, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the product of `a` and `b`.
     */
    function mul(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.mul(b));
    }

    /**
     * @notice Multiplies two `Unsigned`s and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mulCeil(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        uint256 mulRaw = a.rawValue.mul(b.rawValue);
        uint256 mulFloor = mulRaw / FP_SCALING_FACTOR;
        uint256 mod = mulRaw.mod(FP_SCALING_FACTOR);
        if (mod != 0) {
            return Unsigned(mulFloor.add(1));
        } else {
            return Unsigned(mulFloor);
        }
    }

    /**
     * @notice Multiplies an `Unsigned` and an unscaled uint256 and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mulCeil(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        // Since b is an int, there is no risk of truncation and we can just mul it normally
        return Unsigned(a.rawValue.mul(b));
    }

    /**
     * @notice Divides one `Unsigned` by an `Unsigned`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        // There are two caveats with this computation:
        // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
        // 10^41 is stored internally as a uint256 10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
        // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
        return Unsigned(a.rawValue.mul(FP_SCALING_FACTOR).div(b.rawValue));
    }

    /**
     * @notice Divides one `Unsigned` by an unscaled uint256, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.div(b));
    }

    /**
     * @notice Divides one unscaled uint256 by an `Unsigned`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a uint256 numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(uint256 a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return div(fromUnscaledUint(a), b);
    }

    /**
     * @notice Divides one `Unsigned` by an `Unsigned` and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divCeil(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        uint256 aScaled = a.rawValue.mul(FP_SCALING_FACTOR);
        uint256 divFloor = aScaled.div(b.rawValue);
        uint256 mod = aScaled.mod(b.rawValue);
        if (mod != 0) {
            return Unsigned(divFloor.add(1));
        } else {
            return Unsigned(divFloor);
        }
    }

    /**
     * @notice Divides one `Unsigned` by an unscaled uint256 and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divCeil(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        // Because it is possible that a quotient gets truncated, we can't just call "Unsigned(a.rawValue.div(b))"
        // similarly to mulCeil with a uint256 as the second parameter. Therefore we need to convert b into an Unsigned.
        // This creates the possibility of overflow if b is very large.
        return divCeil(a, fromUnscaledUint(b));
    }

    /**
     * @notice Raises an `Unsigned` to the power of an unscaled uint256, reverting on overflow. E.g., `b=2` squares `a`.
     * @dev This will "floor" the result.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return output is `a` to the power of `b`.
     */
    function pow(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory output) {
        output = fromUnscaledUint(1);
        for (uint256 i = 0; i < b; i = i.add(1)) {
            output = mul(output, a);
        }
    }

    // ------------------------------------------------- SIGNED -------------------------------------------------------------
    // Supports 18 decimals. E.g., 1e18 represents "1", 5e17 represents "0.5".
    // For signed values:
    //   This can represent a value up (or down) to +-(2^255 - 1)/10^18 = ~10^58. 10^58 will be stored internally as int256 10^76.
    int256 private constant SFP_SCALING_FACTOR = 10**18;

    struct Signed {
        int256 rawValue;
    }

    function fromSigned(Signed memory a) internal pure returns (Unsigned memory) {
        require(a.rawValue >= 0, "Negative value provided");
        return Unsigned(uint256(a.rawValue));
    }

    function fromUnsigned(Unsigned memory a) internal pure returns (Signed memory) {
        require(a.rawValue <= uint256(type(int256).max), "Unsigned too large");
        return Signed(int256(a.rawValue));
    }

    /**
     * @notice Constructs a `Signed` from an unscaled int, e.g., `b=5` gets stored internally as `5*(10**18)`.
     * @param a int to convert into a FixedPoint.Signed.
     * @return the converted FixedPoint.Signed.
     */
    function fromUnscaledInt(int256 a) internal pure returns (Signed memory) {
        return Signed(a.mul(SFP_SCALING_FACTOR));
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a int256.
     * @return True if equal, or False.
     */
    function isEqual(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue == fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if equal, or False.
     */
    function isEqual(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue == b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue > fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue >= fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue < fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a < b`, or False.
     */
    function isLessThan(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue <= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue <= fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue <= b.rawValue;
    }

    /**
     * @notice The minimum of `a` and `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the minimum of `a` and `b`.
     */
    function min(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return a.rawValue < b.rawValue ? a : b;
    }

    /**
     * @notice The maximum of `a` and `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the maximum of `a` and `b`.
     */
    function max(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return a.rawValue > b.rawValue ? a : b;
    }

    /**
     * @notice Adds two `Signed`s, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the sum of `a` and `b`.
     */
    function add(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.add(b.rawValue));
    }

    /**
     * @notice Adds an `Signed` to an unscaled int, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the sum of `a` and `b`.
     */
    function add(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return add(a, fromUnscaledInt(b));
    }

    /**
     * @notice Subtracts two `Signed`s, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the difference of `a` and `b`.
     */
    function sub(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.sub(b.rawValue));
    }

    /**
     * @notice Subtracts an unscaled int256 from an `Signed`, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the difference of `a` and `b`.
     */
    function sub(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return sub(a, fromUnscaledInt(b));
    }

    /**
     * @notice Subtracts an `Signed` from an unscaled int256, reverting on overflow.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return the difference of `a` and `b`.
     */
    function sub(int256 a, Signed memory b) internal pure returns (Signed memory) {
        return sub(fromUnscaledInt(a), b);
    }

    /**
     * @notice Multiplies two `Signed`s, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mul(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        // There are two caveats with this computation:
        // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
        // stored internally as an int256 ~10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
        // would round to 3, but this computation produces the result 2.
        // No need to use SafeMath because SFP_SCALING_FACTOR != 0.
        return Signed(a.rawValue.mul(b.rawValue) / SFP_SCALING_FACTOR);
    }

    /**
     * @notice Multiplies an `Signed` and an unscaled int256, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the product of `a` and `b`.
     */
    function mul(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.mul(b));
    }

    /**
     * @notice Multiplies two `Signed`s and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mulAwayFromZero(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        int256 mulRaw = a.rawValue.mul(b.rawValue);
        int256 mulTowardsZero = mulRaw / SFP_SCALING_FACTOR;
        // Manual mod because SignedSafeMath doesn't support it.
        int256 mod = mulRaw % SFP_SCALING_FACTOR;
        if (mod != 0) {
            bool isResultPositive = isLessThan(a, 0) == isLessThan(b, 0);
            int256 valueToAdd = isResultPositive ? int256(1) : int256(-1);
            return Signed(mulTowardsZero.add(valueToAdd));
        } else {
            return Signed(mulTowardsZero);
        }
    }

    /**
     * @notice Multiplies an `Signed` and an unscaled int256 and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mulAwayFromZero(Signed memory a, int256 b) internal pure returns (Signed memory) {
        // Since b is an int, there is no risk of truncation and we can just mul it normally
        return Signed(a.rawValue.mul(b));
    }

    /**
     * @notice Divides one `Signed` by an `Signed`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        // There are two caveats with this computation:
        // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
        // 10^41 is stored internally as an int256 10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
        // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
        return Signed(a.rawValue.mul(SFP_SCALING_FACTOR).div(b.rawValue));
    }

    /**
     * @notice Divides one `Signed` by an unscaled int256, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b an int256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.div(b));
    }

    /**
     * @notice Divides one unscaled int256 by an `Signed`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a an int256 numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(int256 a, Signed memory b) internal pure returns (Signed memory) {
        return div(fromUnscaledInt(a), b);
    }

    /**
     * @notice Divides one `Signed` by an `Signed` and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divAwayFromZero(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        int256 aScaled = a.rawValue.mul(SFP_SCALING_FACTOR);
        int256 divTowardsZero = aScaled.div(b.rawValue);
        // Manual mod because SignedSafeMath doesn't support it.
        int256 mod = aScaled % b.rawValue;
        if (mod != 0) {
            bool isResultPositive = isLessThan(a, 0) == isLessThan(b, 0);
            int256 valueToAdd = isResultPositive ? int256(1) : int256(-1);
            return Signed(divTowardsZero.add(valueToAdd));
        } else {
            return Signed(divTowardsZero);
        }
    }

    /**
     * @notice Divides one `Signed` by an unscaled int256 and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b an int256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divAwayFromZero(Signed memory a, int256 b) internal pure returns (Signed memory) {
        // Because it is possible that a quotient gets truncated, we can't just call "Signed(a.rawValue.div(b))"
        // similarly to mulCeil with an int256 as the second parameter. Therefore we need to convert b into an Signed.
        // This creates the possibility of overflow if b is very large.
        return divAwayFromZero(a, fromUnscaledInt(b));
    }

    /**
     * @notice Raises an `Signed` to the power of an unscaled uint256, reverting on overflow. E.g., `b=2` squares `a`.
     * @dev This will "floor" the result.
     * @param a a FixedPoint.Signed.
     * @param b a uint256 (negative exponents are not allowed).
     * @return output is `a` to the power of `b`.
     */
    function pow(Signed memory a, uint256 b) internal pure returns (Signed memory output) {
        output = fromUnscaledInt(1);
        for (uint256 i = 0; i < b; i = i.add(1)) {
            output = mul(output, a);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { DataTypes } from "../../libraries/DataTypes.sol";

interface IOptionRegistry {
    function implementations(address) external view returns (bool);

    function assets(address) external view returns (bool, string memory, string memory);

    function owner() external view returns (address);

    function options(bytes32) external view returns (address);

    function isOption(address) external view returns (bool);

    function optionTokenLogic() external view returns (address);

    function getOptionAddress(DataTypes.Option memory data) external view returns (address, bool);

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
library SafeMath {
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
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMath {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}