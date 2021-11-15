// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { ILongShortPairCreator } from "../interfaces/LongShortPairCreator.sol";
import { ILongShortPair } from "../interfaces/LongShortPair.sol";
import { ICoveredCallFinancialLibrary } from "../interfaces/CoveredCallFinancialLibrary.sol";

import { DateTimeLibrary } from "../libraries/DateTimeLibrary.sol";
import { DataTypes } from "../libraries/DataTypes.sol";

/**
 * @author Tesseract Labs
 * @title Option Factory
 */
contract OptionFactory is Ownable {
    using DateTimeLibrary for uint64;
    using SafeERC20 for IERC20;

    /* ============ Constants ============ */
    // 1 Whole option in wei
    uint256 constant OPTION_UNITS = 10 ** 18;

    /* ============ Immutables ============ */

    // An instance of Long-Short pair to create new Long-Short Pair Tokens
    ILongShortPairCreator public immutable LSP_CREATOR;
    // An instance of UMA Covered Call Financial Product Library
    ICoveredCallFinancialLibrary public immutable COVERED_CALL_FPL;

    /* ============ State Variables ============ */

    // A mapping of approved collaterals. Set by owner / governance
    mapping(address => DataTypes.Collateral) public collaterals;
    // A mapping of approved expiry timestamps. Set by owner / governance
    mapping(uint64 => bool) public expiryTimestamps;
    // An array of valid expiry timestamps
    uint64[] public timestamps;
    // Mapping all options by collateral
    mapping(address => DataTypes.Option[]) optionsByCollateral;
    // Mapping all options by expiry
    mapping(uint64 => DataTypes.Option[]) optionsByExpiry;
    // Mapping of available LSPs
    mapping(address => bool) lsps;

    /* ============ Constructor ============ */

    /**
     * @notice Contract initialization
     *
     * @param lspCreator The address of UMA Long-Short Pair Creator
     */
    constructor(ILongShortPairCreator lspCreator, ICoveredCallFinancialLibrary coveredCall) {
        LSP_CREATOR = lspCreator;
        COVERED_CALL_FPL = coveredCall;
    }

    /* ============ State Changing Methods ============ */

    /**
     * @notice Create a new option token by specifying collateral, expiry and strike price
     *
     * @param expiry The timestamp of the option expiry
     * @param collateral Address of the collateral
     * @param strikePrice Strike price in wei
     *
     * @return lsp Address of the long short pair created
     */
    function createOption(
        uint64 expiry,
        address collateral,
        uint256 strikePrice,
        uint256 initialMint
    ) external returns (address lsp) {
        DataTypes.Collateral memory collateralData = collaterals[collateral];

        require(collateralData.isActive, "OptionFactory::collateral-is-not-active");
        require(expiry > block.timestamp + 86400, "OptionFactory::invalid-expiry");
        require(expiryTimestamps[expiry], "OptionFactory::expiry-not-approved");
        require(initialMint > 0, "OptionFactory::cannot-mint-zero");

        string memory tokenName;
        string memory tokenSymbol;

        uint256 tokenUnits;

        (tokenName, tokenSymbol) = expiry.getTokenName(strikePrice, collateralData.name, collateralData.symbol);

        try IERC20Metadata(collateral).decimals() returns (uint8 decimals) {
            tokenUnits = 10 ** decimals;
        } catch {
            tokenUnits = 10 ** 18;
        }

        lsp = LSP_CREATOR.createLongShortPair(
            expiry,
            tokenUnits,
            collateralData.priceIdentifier,
            tokenName,
            tokenSymbol,
            collateral,
            address(COVERED_CALL_FPL),
            bytes(""),
            0
        );

        lsps[lsp] = true;

        COVERED_CALL_FPL.setLongShortPairParameters(lsp, strikePrice);

        IERC20 longToken = IERC20(ILongShortPair(lsp).longToken());
        IERC20 shortToken = IERC20(ILongShortPair(lsp).shortToken());

        uint256 collateralRequired = initialMint * tokenUnits / OPTION_UNITS;

        IERC20(collateral).safeTransferFrom(msg.sender, address(this), collateralRequired);
        IERC20(collateral).safeApprove(lsp, 0);
        IERC20(collateral).safeApprove(lsp, collateralRequired);

        uint256 collateralUsed = ILongShortPair(lsp).create(initialMint);
        require(collateralUsed == collateralRequired, "OptionFactory::invalid-token-decimal-mismatch");

        longToken.safeTransfer(msg.sender, initialMint);
        shortToken.safeTransfer(msg.sender, initialMint);

        DataTypes.Option memory option = DataTypes.Option({
            expiry: expiry,
            strikePrice: strikePrice,
            collateral: collateral,
            lsp: lsp,
            longToken: address(longToken),
            shortToken: address(shortToken)
        });

        optionsByCollateral[collateral].push(option);
        optionsByExpiry[expiry].push(option);
    }

    /* ============ View Methods ============ */

    /**
     * @notice Fetch an array of all options specifying an expiry
     */
    function getOptionsByExpiry(uint64 expiry) external view returns (DataTypes.Option[] memory options) {
        options = optionsByExpiry[expiry];
    }

    /**
     * @notice Fetch an array of all options specifying the collateral
     */
    function getOptionsByCollateral(address collateral) external view returns (DataTypes.Option[] memory options) {
        options = optionsByCollateral[collateral];
    }

    /* ============ Admin Methods ============ */

    /**
     * @notice Method to activate a token as a collateral
     *
     * Collateral must be approved by UMA as well
     *
     * @param collateral Address of the collateral
     * @param id UMA Price identifier of the collateral
     * @param name Collateral name
     * @param collateral Collateral symbol
     */
    function approveCollateral(address collateral, bytes32 id, string memory name, string memory symbol) external onlyOwner {
        require(bytes(name).length != 0, "OptionFactory::invalid-name");
        require(bytes(symbol).length != 0, "OptionFactory::invalid-symbol");

        collaterals[collateral] = DataTypes.Collateral({
            isActive: true,
            priceIdentifier: id,
            name: name,
            symbol: symbol
        });
    }

    /**
     * @notice Method to remove a token from approved collaterals
     *
     * @param collateral Address of the collateral
     */
    function removeCollateral(address collateral) external onlyOwner {
        require(collaterals[collateral].isActive, "OptionFactory::collateral-not-approved");
        
        DataTypes.Collateral storage collateralData = collaterals[collateral];
        collateralData.isActive = false;
    }

    /**
     * @notice Method to approve a timestamp
     *
     * @param expiry Unix timestamp to approve
     */
    function approveExpiry(uint64 expiry) external onlyOwner {
        require(expiry > block.timestamp + 86400, "OptionFactory::timestamp-invalid");
        require(expiry.getMinute() == 0, "OptionFactory::invalid-expiry-time-minute");
        require(expiry.getSecond() == 0, "OptionFactory::invalid-expiry-time-seconds");
        expiryTimestamps[expiry] = true;
        timestamps.push(expiry);
    }

    /**
     * @notice Method to revoke a timestamp from the approved list
     *
     * @param expiry Unix timestamp to revoke
     */
    function revokeExpiry(uint64 expiry) external onlyOwner {
        require(expiryTimestamps[expiry], "OptionFactory::expiry-not-approved");
        require(expiry > block.timestamp, "OptionFactory::timestamp-in-the-past");
        expiryTimestamps[expiry] = false;

        uint256 index;

        while (timestamps[index] != expiry) {
            index++;
        }

        delete timestamps[index];
    }
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
    constructor () {
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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

    function create(uint256 tokensToCreate) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICoveredCallFinancialLibrary {
    /**
     * @notice Enables any address to set the strike price for an associated LSP.
     * @param LongShortPair address of the LSP.
     * @param strikePrice the strike price for the covered call for the associated LSP.
     * @dev Note: a) Any address can set the initial strike price b) A strike price cannot be 0.
     * c) A strike price can only be set once to prevent the deployer from changing the strike after the fact.
     * d) For safety, a strike price should be set before depositing any synthetic tokens in a liquidity pool.
     * e) financialProduct must expose an expirationTimestamp method to validate it is correctly deployed.
     */
    function setLongShortPairParameters(address LongShortPair, uint256 strikePrice) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title Date and time library
 */
library DateTimeLibrary {
    uint64 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint64 constant SECONDS_PER_HOUR = 60 * 60;
    uint64 constant SECONDS_PER_MINUTE = 60;
    int64 constant OFFSET19700101 = 2440588;

    uint256 private constant STRIKE_PRICE_SCALE = 1e18;
    uint256 private constant STRIKE_PRICE_DIGITS = 18;

    /**
     * @notice Authored by BokkyPooBah
     */
    function _daysToDate(uint64 _days) internal pure returns (uint64 year, uint64 month, uint64 day) {
        int64 __days = int64(_days);

        int64 L = __days + 68569 + OFFSET19700101;
        int64 N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int64 _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int64 _month = 80 * L / 2447;
        int64 _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint64(_year);
        month = uint64(_month);
        day = uint64(_day);
    }

    /**
     * @notice Authored by BokkyPooBah
     */
    function timestampToDate(uint64 timestamp) internal pure returns (uint64 year, uint64 month, uint64 day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    /**
     * @notice Authored by mxwtnb (Charm Finance)
     */
    function getMonthString(uint64 month) internal pure returns (string memory shortString, string memory longString) {
        if (month == 1) {
            return ("JAN", "January");
        } else if (month == 2) {
            return ("FEB", "February");
        } else if (month == 3) {
            return ("MAR", "March");
        } else if (month == 4) {
            return ("APR", "April");
        } else if (month == 5) {
            return ("MAY", "May");
        } else if (month == 6) {
            return ("JUN", "June");
        } else if (month == 7) {
            return ("JUL", "July");
        } else if (month == 8) {
            return ("AUG", "August");
        } else if (month == 9) {
            return ("SEP", "September");
        } else if (month == 10) {
            return ("OCT", "October");
        } else if (month == 11) {
            return ("NOV", "November");
        } else {
            return ("DEC", "December");
        }
    }

    function getTokenName(
        uint64 timestamp,
        uint256 strikePrice,
        string memory name,
        string memory symbol
    ) internal pure returns (string memory tokenName, string memory tokenSymbol) {
        (uint64 year, uint64 month, uint64 day) = timestampToDate(timestamp);
        (string memory shortMonth, ) = getMonthString(month);
        string memory displayStrikePrice = getDisplayedStrikePrice(strikePrice);

        tokenName = string(abi.encodePacked(
            "Polynomial ",
            name,
            " Call ",
            uintTo2Chars(day),
            shortMonth,
            toString(year),
            " ",
            displayStrikePrice
        ));

        tokenSymbol = string(abi.encodePacked(
            "P-",
            symbol,
            "-",
            uintTo2Chars(day),
            shortMonth,
            toString(year),
            "-",
            displayStrikePrice,
            "-C"
        ));
    }

    /**
     * @notice Authored by BokkyPooBah
     */
    function getHour(uint64 timestamp) internal pure returns (uint64 hour) {
        uint64 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }

    /**
     * @notice Authored by BokkyPooBah
     */
    function getMinute(uint64 timestamp) internal pure returns (uint64 minute) {
        uint64 secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }

    /**
     * @notice Authored by BokkyPooBah
     */
    function getSecond(uint64 timestamp) internal pure returns (uint64 second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    /**
     * @notice Authored by mxwtnb (Charm Finance)
     * @dev return a representation of a number using 2 characters, adds a leading 0 if one digit, uses two trailing digits if a 3 digit number
     * @return str 2 characters that corresponds to a number
     */
    function uintTo2Chars(uint64 number) internal pure returns (string memory str) {
        if (number > 99) number = number % 100;
        str = toString(number);
        if (number < 10) {
            return string(abi.encodePacked("0", str));
        }
        return str;
    }

    /**
     * @notice Authored by mxwtnb (Charm Finance)
     * @dev convert strike price scaled by 1e8 to human readable number string
     * @param _strikePrice strike price scaled by 1e8
     * @return strike price string
     */
    function getDisplayedStrikePrice(uint256 _strikePrice) internal pure returns (string memory) {
        uint256 remainder = _strikePrice % STRIKE_PRICE_SCALE;
        uint256 quotient = _strikePrice / STRIKE_PRICE_SCALE;
        string memory quotientStr = toString256(quotient);

        if (remainder == 0) return quotientStr;

        uint256 trailingZeroes = 0;
        while (remainder % 10 == 0) {
            remainder = remainder / 10;
            trailingZeroes += 1;
        }

        // pad the number with "1 + starting zeroes"
        remainder += 10**(STRIKE_PRICE_DIGITS - trailingZeroes);

        string memory tmpStr = toString256(remainder);
        tmpStr = slice(tmpStr, 1, 1 + STRIKE_PRICE_DIGITS - trailingZeroes);

        string memory completeStr = string(abi.encodePacked(quotientStr, ".", tmpStr));
        return completeStr;
    }

    /**
     * @notice Authored by mxwtnb (Charm Finance)
     * @dev cut string s into s[start:end]
     * @param _s the string to cut
     * @param _start the starting index
     * @param _end the ending index (excluded in the substring)
     */
    function slice(
        string memory _s,
        uint256 _start,
        uint256 _end
    ) internal pure returns (string memory) {
        bytes memory a = new bytes(_end - _start);
        for (uint256 i = 0; i < _end - _start; i++) {
            a[i] = bytes(_s)[_start + i];
        }
        return string(a);
    }



    /**
     * @notice Authored by OpenZeppelin
     * @dev Converts a `uint64` to its ASCII `string` decimal representation.
     */
    function toString(uint64 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint64 temp = value;
        uint64 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint64(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @notice Authored by OpenZeppelin
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString256(uint256 value) internal pure returns (string memory) {
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library DataTypes {
    struct Collateral {
        bool isActive;
        bytes32 priceIdentifier;
        string name;
        string symbol;
    }

    struct Option {
        uint64 expiry;
        uint256 strikePrice;
        address collateral;
        address lsp;
        address longToken;
        address shortToken;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

