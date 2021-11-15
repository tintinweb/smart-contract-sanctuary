// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.4;

import "@paulrberg/contracts/access/Ownable.sol";
import "@paulrberg/contracts/token/erc20/Erc20.sol";
import "@paulrberg/contracts/token/erc20/Erc20Permit.sol";
import "@paulrberg/contracts/token/erc20/Erc20Recover.sol";
import "@paulrberg/contracts/token/erc20/SafeErc20.sol";

import "./IHToken.sol";
import "../balanceSheet/IBalanceSheetV1.sol";

/// @notice Emitted when the bond did not mature.
error HToken__BondNotMatured(uint256 maturity);

/// @notice Emitted when burning hTokens and the caller is not the BalanceSheet contract.
error HToken__BurnNotAuthorized(address caller);

/// @notice Emitted when the maturity is in the past.
error HToken__MaturityPast(uint256 maturity);

/// @notice Emitted when minting hTokens and the caller is not the BalanceSheet contract.
error HToken__MintNotAuthorized(address caller);

/// @notice Emitted when redeeming more underlying that there is in the reserve.
error HToken__RedeemInsufficientLiquidity(uint256 underlyingAmount, uint256 totalUnderlyingReserve);

/// @notice Emitted when redeeming a zero amount of hTokens.
error HToken__RedeemZero();

/// @notice Emitted when supplying a zero amount of underlying.
error HToken__SupplyUnderlyingZero();

/// @notice Emitted when constructing the contract and the underlying has more than 18 decimals.
error HToken__UnderlyingDecimalsOverflow(uint256 decimals);

/// @notice Emitted when constructing the contract and the underlying has zero decimals.
error HToken__UnderlyingDecimalsZero();

/// @title HToken
/// @author Hifi
contract HToken is
    Ownable, // one dependency
    Erc20, // one dependency
    Erc20Permit, // four dependencies
    IHToken, // five dependencies
    Erc20Recover // five dependencies
{
    using SafeErc20 for IErc20;

    /// PUBLIC STORAGE ///

    /// @inheritdoc IHToken
    IBalanceSheetV1 public override balanceSheet;

    /// @inheritdoc IHToken
    uint256 public override maturity;

    /// @inheritdoc IHToken
    uint256 public override totalUnderlyingReserve;

    /// @inheritdoc IHToken
    IErc20 public override underlying;

    /// @inheritdoc IHToken
    uint256 public override underlyingPrecisionScalar;

    /// CONSTRUCTOR ///

    /// @notice The hToken always has 18 decimals.
    /// @param name_ Erc20 name of this token.
    /// @param symbol_ Erc20 symbol of this token.
    /// @param maturity_ Unix timestamp in seconds for when this token matures.
    /// @param balanceSheet_ The address of the BalanceSheet contract.
    /// @param underlying_ The contract address of the underlying asset.
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maturity_,
        IBalanceSheetV1 balanceSheet_,
        IErc20 underlying_
    ) Erc20Permit(name_, symbol_, 18) Ownable() {
        // Set the maturity.
        if (maturity_ <= block.timestamp) {
            revert HToken__MaturityPast(maturity_);
        }
        maturity = maturity_;

        // Set the BalanceSheet contract.
        balanceSheet = balanceSheet_;

        // Set the underlying contract and calculate the precision scalar.
        uint256 underlyingDecimals = underlying_.decimals();
        if (underlyingDecimals == 0) {
            revert HToken__UnderlyingDecimalsZero();
        }
        if (underlyingDecimals > 18) {
            revert HToken__UnderlyingDecimalsOverflow(underlyingDecimals);
        }
        underlyingPrecisionScalar = 10**(18 - underlyingDecimals);
        underlying = underlying_;

        // Set the list of non-recoverable tokens.
        nonRecoverableTokens.push(underlying);
        isRecoverInitialized = true;
    }

    /// PUBLIC CONSTANT FUNCTIONS ///

    /// @inheritdoc IHToken
    function isMatured() public view override returns (bool) {
        return block.timestamp >= maturity;
    }

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc IHToken
    function burn(address holder, uint256 burnAmount) external override {
        // Checks: the caller is the BalanceSheet.
        if (msg.sender != address(balanceSheet)) {
            revert HToken__BurnNotAuthorized(msg.sender);
        }

        // Effects: burns the hTokens.
        burnInternal(holder, burnAmount);

        // Emit a Burn and a Transfer event.
        emit Burn(holder, burnAmount);
    }

    /// @inheritdoc IHToken
    function mint(address beneficiary, uint256 mintAmount) external override {
        // Checks: the caller is the BalanceSheet.
        if (msg.sender != address(balanceSheet)) {
            revert HToken__MintNotAuthorized(msg.sender);
        }

        // Effects: print the new hTokens into existence.
        mintInternal(beneficiary, mintAmount);

        // Emit a Mint event.
        emit Mint(beneficiary, mintAmount);
    }

    /// @inheritdoc IHToken
    function redeem(uint256 hTokenAmount) external override {
        // Checks: before maturation.
        if (!isMatured()) {
            revert HToken__BondNotMatured(maturity);
        }

        // Checks: the zero edge case.
        if (hTokenAmount == 0) {
            revert HToken__RedeemZero();
        }

        // Denormalize the hToken amount to the underlying decimals.
        uint256 underlyingAmount;
        if (underlyingPrecisionScalar != 1) {
            unchecked {
                underlyingAmount = hTokenAmount / underlyingPrecisionScalar;
            }
        } else {
            underlyingAmount = hTokenAmount;
        }

        // Checks: there is enough liquidity.
        if (underlyingAmount > totalUnderlyingReserve) {
            revert HToken__RedeemInsufficientLiquidity(underlyingAmount, totalUnderlyingReserve);
        }

        // Effects: decrease the remaining supply of underlying.
        totalUnderlyingReserve -= underlyingAmount;

        // Interactions: burn the hTokens.
        burnInternal(msg.sender, hTokenAmount);

        // Interactions: perform the Erc20 transfer.
        underlying.safeTransfer(msg.sender, underlyingAmount);

        emit Redeem(msg.sender, hTokenAmount, underlyingAmount);
    }

    /// @inheritdoc IHToken
    function supplyUnderlying(uint256 underlyingSupplyAmount) external override {
        // Checks: the zero edge case.
        if (underlyingSupplyAmount == 0) {
            revert HToken__SupplyUnderlyingZero();
        }

        // Effects: update storage.
        totalUnderlyingReserve += underlyingSupplyAmount;

        // Normalize the underlying amount to 18 decimals.
        uint256 hTokenAmount;
        if (underlyingPrecisionScalar != 1) {
            hTokenAmount = underlyingSupplyAmount * underlyingPrecisionScalar;
        } else {
            hTokenAmount = underlyingSupplyAmount;
        }

        // Effects: mint the hTokens.
        mintInternal(msg.sender, hTokenAmount);

        // Interactions: perform the Erc20 transfer.
        underlying.safeTransferFrom(msg.sender, address(this), underlyingSupplyAmount);

        emit SupplyUnderlying(msg.sender, underlyingSupplyAmount, hTokenAmount);
    }

    /// @inheritdoc IHToken
    function _setBalanceSheet(IBalanceSheetV1 newBalanceSheet) external override onlyOwner {
        // Effects: update storage.
        IBalanceSheetV1 oldBalanceSheet = balanceSheet;
        balanceSheet = newBalanceSheet;

        emit SetBalanceSheet(owner, oldBalanceSheet, newBalanceSheet);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "./IOwnable.sol";

/// @notice Emitted when the caller is not the owner.
error Ownable__NotOwner(address owner, address caller);

/// @notice Emitted when setting the owner to the zero address.
error Ownable__OwnerZeroAddress();

/// @title Ownable
/// @author Paul Razvan Berg
contract Ownable is IOwnable {
    /// PUBLIC STORAGE ///

    /// @inheritdoc IOwnable
    address public override owner;

    /// MODIFIERS ///

    /// @notice Throws if called by any account other than the owner.
    modifier onlyOwner() {
        if (owner != msg.sender) {
            revert Ownable__NotOwner(owner, msg.sender);
        }
        _;
    }

    /// CONSTRUCTOR ///

    /// @notice Initializes the contract setting the deployer as the initial owner.
    constructor() {
        address msgSender = msg.sender;
        owner = msgSender;
        emit TransferOwnership(address(0), msgSender);
    }

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc IOwnable
    function _renounceOwnership() public virtual override onlyOwner {
        emit TransferOwnership(owner, address(0));
        owner = address(0);
    }

    /// @inheritdoc IOwnable
    function _transferOwnership(address newOwner) public virtual override onlyOwner {
        if (newOwner == address(0)) {
            revert Ownable__OwnerZeroAddress();
        }
        emit TransferOwnership(owner, newOwner);
        owner = newOwner;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "./IErc20.sol";

/// @notice Emitted when the owner is the zero address.
error Erc20__ApproveOwnerZeroAddress();

/// @notice Emitted when the spender is the zero address.
error Erc20__ApproveSpenderZeroAddress();

/// @notice Emitted when burning more tokens than are in the account.
error Erc20__BurnUnderflow(uint256 accountBalance, uint256 burnAmount);

/// @notice Emitted when the holder is the zero address.
error Erc20__BurnZeroAddress();

/// @notice Emitted when the owner did not give the spender sufficient allowance.
error Erc20__InsufficientAllowance(uint256 allowance, uint256 amount);

/// @notice Emitted when tranferring more tokens than there are in the account.
error Erc20__InsufficientBalance(uint256 senderBalance, uint256 amount);

/// @notice Emitted when the beneficiary is the zero address.
error Erc20__MintZeroAddress();

/// @notice Emitted when the sender is the zero address.
error Erc20__TransferSenderZeroAddress();

/// @notice Emitted when the recipient is the zero address.
error Erc20__TransferRecipientZeroAddress();

/// @title Erc20
/// @author Paul Razvan Berg
contract Erc20 is IErc20 {
    /// PUBLIC STORAGE ///

    /// @inheritdoc IErc20
    string public override name;

    /// @inheritdoc IErc20
    string public override symbol;

    /// @inheritdoc IErc20
    uint8 public immutable override decimals;

    /// @inheritdoc IErc20
    uint256 public override totalSupply;

    /// INTERNAL STORAGE ///

    /// @dev Internal mapping of balances.
    mapping(address => uint256) internal balances;

    /// @dev Internal mapping of allowances.
    mapping(address => mapping(address => uint256)) internal allowances;

    /// CONSTRUCTOR ///

    /// @notice All three of these arguments are immutable: they can only be set once during construction.
    /// @param name_ Erc20 name of this token.
    /// @param symbol_ Erc20 symbol of this token.
    /// @param decimals_ Erc20 decimal precision of this token.
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
    }

    /// PUBLIC CONSTANT FUNCTIONS ///

    /// @inheritdoc IErc20
    function allowance(address owner, address spender) public view override returns (uint256) {
        return allowances[owner][spender];
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return balances[account];
    }

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc IErc20
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        approveInternal(msg.sender, spender, amount);
        return true;
    }

    /// @inheritdoc IErc20
    function decreaseAllowance(address spender, uint256 subtractedAmount) public virtual override returns (bool) {
        uint256 newAllowance = allowances[msg.sender][spender] - subtractedAmount;
        approveInternal(msg.sender, spender, newAllowance);
        return true;
    }

    /// @inheritdoc IErc20
    function increaseAllowance(address spender, uint256 addedAmount) public virtual override returns (bool) {
        uint256 newAllowance = allowances[msg.sender][spender] + addedAmount;
        approveInternal(msg.sender, spender, newAllowance);
        return true;
    }

    /// @inheritdoc IErc20
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        transferInternal(msg.sender, recipient, amount);
        return true;
    }

    /// @inheritdoc IErc20
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        transferInternal(sender, recipient, amount);

        uint256 currentAllowance = allowances[sender][msg.sender];
        if (currentAllowance < amount) {
            revert Erc20__InsufficientAllowance(currentAllowance, amount);
        }
        unchecked {
            approveInternal(sender, msg.sender, currentAllowance - amount);
        }

        return true;
    }

    /// INTERNAL NON-CONSTANT FUNCTIONS ///

    /// @notice Sets `amount` as the allowance of `spender` over the `owner`s tokens.
    ///
    /// @dev Emits an {Approval} event.
    ///
    /// Requirements:
    ///
    /// - `owner` cannot be the zero address.
    /// - `spender` cannot be the zero address.
    function approveInternal(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        if (owner == address(0)) {
            revert Erc20__ApproveOwnerZeroAddress();
        }
        if (spender == address(0)) {
            revert Erc20__ApproveSpenderZeroAddress();
        }

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /// @notice Destroys `burnAmount` tokens from `holder`, reducing the token supply.
    ///
    /// @dev Emits a {Transfer} event.
    ///
    /// Requirements:
    ///
    /// - `holder` must have at least `amount` tokens.
    function burnInternal(address holder, uint256 burnAmount) internal {
        if (holder == address(0)) {
            revert Erc20__BurnZeroAddress();
        }

        // Burn the tokens.
        balances[holder] -= burnAmount;

        // Reduce the total supply.
        totalSupply -= burnAmount;

        emit Transfer(holder, address(0), burnAmount);
    }

    /// @notice Prints new tokens into existence and assigns them to `beneficiary`, increasing the
    /// total supply.
    ///
    /// @dev Emits a {Transfer} event.
    ///
    /// Requirements:
    ///
    /// - The beneficiary's balance and the total supply cannot overflow.
    function mintInternal(address beneficiary, uint256 mintAmount) internal {
        if (beneficiary == address(0)) {
            revert Erc20__MintZeroAddress();
        }

        /// Mint the new tokens.
        balances[beneficiary] += mintAmount;

        /// Increase the total supply.
        totalSupply += mintAmount;

        emit Transfer(address(0), beneficiary, mintAmount);
    }

    /// @notice Moves `amount` tokens from `sender` to `recipient`.
    ///
    /// @dev Emits a {Transfer} event.
    ///
    /// Requirements:
    ///
    /// - `sender` cannot be the zero address.
    /// - `recipient` cannot be the zero address.
    /// - `sender` must have a balance of at least `amount`.
    function transferInternal(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        if (sender == address(0)) {
            revert Erc20__TransferSenderZeroAddress();
        }
        if (recipient == address(0)) {
            revert Erc20__TransferRecipientZeroAddress();
        }

        uint256 senderBalance = balances[sender];
        if (senderBalance < amount) {
            revert Erc20__InsufficientBalance(senderBalance, amount);
        }
        unchecked {
            balances[sender] = senderBalance - amount;
        }

        balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }
}

// SPDX-License-Identifier: Unlicense
// solhint-disable var-name-mixedcase
pragma solidity >=0.8.4;

import "./Erc20.sol";
import "./IErc20Permit.sol";

/// @notice Emitted when the recovered owner does not match the actual owner.
error Erc20Permit__InvalidSignature(uint8 v, bytes32 r, bytes32 s);

/// @notice Emitted when the owner is the zero address.
error Erc20Permit__OwnerZeroAddress();

/// @notice Emitted when the permit expired.
error Erc20Permit__PermitExpired(uint256 deadline);

/// @notice Emitted when the recovered owner is the zero address.
error Erc20Permit__RecoveredOwnerZeroAddress();

/// @notice Emitted when the spender is the zero address.
error Erc20Permit__SpenderZeroAddress();

/// @title Erc20Permit
/// @author Paul Razvan Berg
contract Erc20Permit is
    IErc20Permit, // one dependency
    Erc20 // one dependency
{
    /// PUBLIC STORAGE ///

    /// @inheritdoc IErc20Permit
    bytes32 public immutable override DOMAIN_SEPARATOR;

    /// @inheritdoc IErc20Permit
    bytes32 public constant override PERMIT_TYPEHASH =
        0xfc77c2b9d30fe91687fd39abb7d16fcdfe1472d065740051ab8b13e4bf4a617f;

    /// @inheritdoc IErc20Permit
    mapping(address => uint256) public override nonces;

    /// @inheritdoc IErc20Permit
    string public constant override version = "1";

    /// CONSTRUCTOR ///

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) Erc20(_name, _symbol, _decimals) {
        uint256 chainId;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                address(this)
            )
        );
    }

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc IErc20Permit
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override {
        if (owner == address(0)) {
            revert Erc20Permit__OwnerZeroAddress();
        }
        if (spender == address(0)) {
            revert Erc20Permit__SpenderZeroAddress();
        }
        if (deadline < block.timestamp) {
            revert Erc20Permit__PermitExpired(deadline);
        }

        // It's safe to use the "+" operator here because the nonce cannot realistically overflow, ever.
        bytes32 hashStruct = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, amount, nonces[owner]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashStruct));
        address recoveredOwner = ecrecover(digest, v, r, s);

        if (recoveredOwner == address(0)) {
            revert Erc20Permit__RecoveredOwnerZeroAddress();
        }
        if (recoveredOwner != owner) {
            revert Erc20Permit__InvalidSignature(v, r, s);
        }

        approveInternal(owner, spender, amount);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "./IErc20.sol";
import "./IErc20Recover.sol";
import "./SafeErc20.sol";
import "../../access/Ownable.sol";

/// @notice Emitted when the contract is initialized.
error Initialized();

/// @notice Emitted when the contract is not initialized.
error NotInitialized();

/// @notice Emitted when recovering a token marked as non-recoverable.
error NonRecoverableToken(address token);

/// @notice Emitted when the amount to recover is zero.
error RecoverZero();

/// @title Erc20Recover
/// @author Paul Razvan Berg
abstract contract Erc20Recover is
    Ownable, // one dependency
    IErc20Recover // two dependencies
{
    using SafeErc20 for IErc20;

    /// PUBLIC STORAGE ///

    /// @inheritdoc IErc20Recover
    IErc20[] public override nonRecoverableTokens;

    /// @dev A flag that signals whether the the non-recoverable tokens were set or not.
    bool internal isRecoverInitialized;

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc IErc20Recover
    function _setNonRecoverableTokens(IErc20[] memory tokens) public override onlyOwner {
        // Checks
        if (isRecoverInitialized) {
            revert Initialized();
        }

        // Iterate over the token list, sanity check each and update the mapping.
        uint256 length = tokens.length;
        for (uint256 i = 0; i < length; i += 1) {
            tokens[i].symbol();
            nonRecoverableTokens.push(tokens[i]);
        }

        // Effects: prevent this function from ever being called again.
        isRecoverInitialized = true;

        emit SetNonRecoverableTokens(owner, tokens);
    }

    /// @inheritdoc IErc20Recover
    function _recover(IErc20 token, uint256 recoverAmount) public override onlyOwner {
        // Checks
        if (!isRecoverInitialized) {
            revert NotInitialized();
        }

        if (recoverAmount == 0) {
            revert RecoverZero();
        }

        bytes32 tokenSymbolHash = keccak256(bytes(token.symbol()));
        uint256 length = nonRecoverableTokens.length;

        // We iterate over the non-recoverable token array and check that:
        //
        //   1. The addresses of the tokens are not the same.
        //   2. The symbols of the tokens are not the same.
        //
        // It is true that the second check may lead to a false positive, but there is no better way
        // to fend off against proxied tokens.
        for (uint256 i = 0; i < length; i += 1) {
            if (
                address(token) == address(nonRecoverableTokens[i]) ||
                tokenSymbolHash == keccak256(bytes(nonRecoverableTokens[i].symbol()))
            ) {
                revert NonRecoverableToken(address(token));
            }
        }

        // Interactions
        token.safeTransfer(owner, recoverAmount);

        emit Recover(owner, token, recoverAmount);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "./IErc20.sol";
import "../../utils/Address.sol";

/// @notice Emitted when the call is made to a non-contract.
error CallToNonContract(address target);

/// @notice Emitted when there is no return data.
error NoReturnData();

/// @title SafeErc20.sol
/// @author Paul Razvan Berg
/// @notice Wraps around Erc20 operations that throw on failure (when the token contract
/// returns false). Tokens that return no value (and instead revert or throw
/// on failure) are also supported, non-reverting calls are assumed to be successful.
///
/// To use this library you can add a `using SafeErc20 for IErc20;` statement to your contract,
/// which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
///
/// @dev Forked from OpenZeppelin
/// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/utils/Address.sol
library SafeErc20 {
    using Address for address;

    /// INTERNAL FUNCTIONS ///

    function safeTransfer(
        IErc20 token,
        address to,
        uint256 amount
    ) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, amount));
    }

    function safeTransferFrom(
        IErc20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, amount));
    }

    /// PRIVATE FUNCTIONS ///

    /// @dev Imitates a Solidity high-level call (a regular function call to a contract), relaxing the requirement
    /// on the return value: the return value is optional (but if data is returned, it cannot be false).
    /// @param token The token targeted by the call.
    /// @param data The call data (encoded using abi.encode or one of its variants).
    function callOptionalReturn(IErc20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.
        bytes memory returndata = functionCall(address(token), data, "SafeErc20LowLevelCall");
        if (returndata.length > 0) {
            // Return data is optional.
            if (!abi.decode(returndata, (bool))) {
                revert NoReturnData();
            }
        }
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) private returns (bytes memory) {
        if (!target.isContract()) {
            revert CallToNonContract(target);
        }

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present.
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly.
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

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.4;

import "@paulrberg/contracts/access/IOwnable.sol";
import "@paulrberg/contracts/token/erc20/IErc20.sol";
import "@paulrberg/contracts/token/erc20/IErc20Permit.sol";
import "@paulrberg/contracts/token/erc20/IErc20Recover.sol";

import "../balanceSheet/IBalanceSheetV1.sol";

/// @title IHToken
/// @author Hifi
/// @notice Zero-coupon bond that tracks an Erc20 underlying asset.
interface IHToken is
    IOwnable, // no dependency
    IErc20Permit, // one dependency
    IErc20Recover // one dependency
{
    /// EVENTS ///

    /// @notice Emitted when tokens are burnt.
    /// @param holder The address of the holder.
    /// @param burnAmount The amount of burnt tokens.
    event Burn(address indexed holder, uint256 burnAmount);

    /// @notice Emitted when tokens are minted.
    /// @param beneficiary The address of the holder.
    /// @param mintAmount The amount of minted tokens.
    event Mint(address indexed beneficiary, uint256 mintAmount);

    /// @notice Emitted when hTokens are redeemed.
    /// @param account The account redeeming the hTokens.
    /// @param hTokenAmount The amount of redeemed hTokens.
    /// @param underlyingAmount The amount of received underlying tokens.
    event Redeem(address indexed account, uint256 hTokenAmount, uint256 underlyingAmount);

    /// @notice Emitted when the BalanceSheet is set.
    /// @param owner The address of the owner.
    /// @param oldBalanceSheet The address of the old BalanceSheet.
    /// @param newBalanceSheet The address of the new BalanceSheet.
    event SetBalanceSheet(address indexed owner, IBalanceSheetV1 oldBalanceSheet, IBalanceSheetV1 newBalanceSheet);

    /// @notice Emitted when underlying is supplied in exchange for an equivalent amount of hTokens.
    /// @param account The account supplying underlying.
    /// @param underlyingAmount The amount of supplied underlying.
    /// @param hTokenAmount The amount of minted hTokens.
    event SupplyUnderlying(address indexed account, uint256 underlyingAmount, uint256 hTokenAmount);

    /// PUBLIC CONSTANT FUNCTIONS ///

    /// @notice The unique BalanceSheet associated with this HToken.
    /// @return The BalanceSheet contract.
    function balanceSheet() external view returns (IBalanceSheetV1);

    /// @notice Checks if the bond matured.
    /// @return bool true = bond matured, otherwise it didn't.
    function isMatured() external view returns (bool);

    /// @notice Unix timestamp in seconds for when this HToken matures.
    function maturity() external view returns (uint256);

    /// @notice The amount of underlying redeemable after maturation.
    function totalUnderlyingReserve() external view returns (uint256);

    /// @notice The Erc20 underlying, or target, asset for this HToken.
    function underlying() external view returns (IErc20);

    /// @notice The ratio between normalized precision (1e18) and the underlying precision.
    function underlyingPrecisionScalar() external view returns (uint256);

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @notice Destroys `burnAmount` tokens from `holder`, reducing the token supply.
    ///
    /// @dev Emits a {Burn} and a {Transfer} event.
    ///
    /// Requirements:
    /// - Can only be called by the BalanceSheet contract.
    ///
    /// @param holder The account whose hTokens to burn.
    /// @param burnAmount The amount of hTokens to burn.
    function burn(address holder, uint256 burnAmount) external;

    /// @notice Prints new tokens into existence and assigns them to `beneficiary`, increasing the total supply.
    ///
    /// @dev Emits a {Mint} and a {Transfer} event.
    ///
    /// Requirements:
    /// - Can only be called by the BalanceSheet contract.
    ///
    /// @param beneficiary The account to mint the hTokens for.
    /// @param mintAmount The amount of hTokens to print into existence.
    function mint(address beneficiary, uint256 mintAmount) external;

    /// @notice Pays the token holder the face value after maturation.
    ///
    /// @dev Emits a {Redeem} event.
    ///
    /// Requirements:
    ///
    /// - Must be called after maturation.
    /// - The amount to redeem cannot be zero.
    /// - There must be enough liquidity in the contract.
    ///
    /// @param hTokenAmount The amount of hTokens to redeem for the underlying asset.
    function redeem(uint256 hTokenAmount) external;

    /// @notice Mints hTokens by supplying an equivalent amount of underlying.
    ///
    /// @dev Emits a {SupplyUnderlying} event.
    ///
    /// Requirements:
    ///
    /// - The amount to supply cannot be zero.
    /// - The caller must have allowed this contract to spend `underlyingAmount` tokens.
    ///
    /// @param underlyingAmount The amount of underlying to supply.
    function supplyUnderlying(uint256 underlyingAmount) external;

    /// @notice Updates the address of the BalanceSheet contract.
    ///
    /// @dev Throws a {SetBalanceSheet} event.
    ///
    /// Requirements:
    /// - The caller must be the owner.
    ///
    /// @param newBalanceSheet The address of the new BalanceSheet contract.
    function _setBalanceSheet(IBalanceSheetV1 newBalanceSheet) external;
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.4;

import "@paulrberg/contracts/token/erc20/IErc20.sol";

import "../fintroller/IFintrollerV1.sol";
import "../hToken/IHToken.sol";
import "../../access/IOwnableUpgradeable.sol";
import "../../oracles/IChainlinkOperator.sol";

/// @title IBalanceSheetV1
/// @author Hifi
/// @notice Manages the collaterals and the debts for all users.
interface IBalanceSheetV1 is IOwnableUpgradeable {
    /// EVENTS ///

    /// @notice Emitted when a borrow is made.
    /// @param account The address of the borrower.
    /// @param bond The address of the bond contract.
    /// @param borrowAmount The amount of hTokens borrowed.
    event Borrow(address indexed account, IHToken indexed bond, uint256 borrowAmount);

    /// @notice Emitted when collateral is deposited.
    /// @param account The address of the borrower.
    /// @param collateral The related collateral.
    /// @param collateralAmount The amount of deposited collateral.
    event DepositCollateral(address indexed account, IErc20 indexed collateral, uint256 collateralAmount);

    /// @notice Emitted when a borrow is liquidated.
    /// @param liquidator The address of the liquidator.
    /// @param borrower The address of the borrower.
    /// @param bond The address of the bond contract.
    /// @param repayAmount The amount of repaid funds.
    /// @param collateral The address of the collateral contract.
    /// @param seizedCollateralAmount The amount of seized collateral.
    event LiquidateBorrow(
        address indexed liquidator,
        address indexed borrower,
        IHToken indexed bond,
        uint256 repayAmount,
        IErc20 collateral,
        uint256 seizedCollateralAmount
    );

    /// @notice Emitted when a borrow is repaid.
    /// @param payer The address of the payer.
    /// @param borrower The address of the borrower.
    /// @param bond The address of the bond contract.
    /// @param repayAmount The amount of repaid funds.
    /// @param newDebtAmount The amount of the new debt.
    event RepayBorrow(
        address indexed payer,
        address indexed borrower,
        IHToken indexed bond,
        uint256 repayAmount,
        uint256 newDebtAmount
    );

    /// @notice Emitted when a new oracle is set.
    /// @param owner The address of the owner.
    /// @param oldOracle The address of the old oracle.
    /// @param newOracle The address of the new oracle.
    event SetOracle(address indexed owner, address oldOracle, address newOracle);

    /// @notice Emitted when collateral is withdrawn.
    /// @param account The address of the borrower.
    /// @param collateral The related collateral.
    /// @param collateralAmount The amount of withdrawn collateral.
    event WithdrawCollateral(address indexed account, IErc20 indexed collateral, uint256 collateralAmount);

    /// CONSTANT FUNCTIONS ///

    /// @notice Returns the list of bond markets the given account entered.
    /// @dev It is not an error to provide an invalid address.
    /// @param account The borrower account to make the query against.
    function getBondList(address account) external view returns (IHToken[] memory);

    /// @notice Returns the amount of collateral deposited by the given account for the given collateral type.
    /// @dev It is not an error to provide an invalid address.
    /// @param account The borrower account to make the query against.
    /// @param collateral The collateral to make the query against.
    function getCollateralAmount(address account, IErc20 collateral) external view returns (uint256 collateralAmount);

    /// @notice Returns the list of collaterals the given account deposited.
    /// @dev It is not an error to provide an invalid address.
    /// @param account The borrower account to make the query against.
    function getCollateralList(address account) external view returns (IErc20[] memory);

    /// @notice Calculates the current account liquidity.
    /// @param account The account to make the query against.
    /// @return excessLiquidity account liquidity in excess of collateral requirements.
    /// @return shortfallLiquidity account shortfall below collateral requirements
    function getCurrentAccountLiquidity(address account)
        external
        view
        returns (uint256 excessLiquidity, uint256 shortfallLiquidity);

    /// @notice Returns the amount of debt accrued by the given account in the given bond market.
    /// @dev It is not an error to provide an invalid address.
    /// @param account The borrower account to make the query against.
    /// @param bond The bond to make the query against.
    function getDebtAmount(address account, IHToken bond) external view returns (uint256 debtAmount);

    /// @notice Calculates the account liquidity given a modified collateral, collateral amount, bond and debt amount,
    /// using the current prices provided by the oracle.
    ///
    /// @dev Works by summing up each collateral amount multiplied by the USD value of each unit and divided by its
    /// respective collateral ratio, then dividing the sum by the total amount of debt drawn by the user.
    ///
    /// Caveats:
    /// - This function expects that the "collateralList" and the "bondList" are each modified in advance to include
    /// the collateral and bond due to be modified.
    ///
    /// @param account The account to make the query against.
    /// @param collateralModify The collateral to make the check against.
    /// @param collateralAmountModify The hypothetical normalized amount of collateral.
    /// @param bondModify The bond to make the check against.
    /// @param debtAmountModify The hypothetical amount of debt.
    /// @return excessLiquidity hypothetical account liquidity in excess of collateral requirements.
    /// @return shortfallLiquidity hypothetical account shortfall below collateral requirements
    function getHypotheticalAccountLiquidity(
        address account,
        IErc20 collateralModify,
        uint256 collateralAmountModify,
        IHToken bondModify,
        uint256 debtAmountModify
    ) external view returns (uint256 excessLiquidity, uint256 shortfallLiquidity);

    /// @notice Calculates the amount of hTokens that should be repaid in order to seize a given amount of collateral.
    /// Note that this is for informational purposes only, it doesn't say anything about whether the user can be
    /// liquidated.
    /// @dev The formula applied:
    /// repayAmount = (seizableCollateralAmount * collateralPriceUsd) / (liquidationIncentive * underlyingPriceUsd)
    /// @param collateral The collateral to make the query against.
    /// @param seizableCollateralAmount The amount of collateral to seize.
    /// @param bond The bond to make the query against.
    /// @return repayAmount The amount of hTokens that should be repaid.
    function getRepayAmount(
        IErc20 collateral,
        uint256 seizableCollateralAmount,
        IHToken bond
    ) external view returns (uint256 repayAmount);

    /// @notice Calculates the amount of collateral that can be seized when liquidating a borrow. Note that this
    /// is for informational purposes only, it doesn't say anything about whether the user can be liquidated.
    /// @dev The formula applied:
    /// seizableCollateralAmount = repayAmount * liquidationIncentive * underlyingPriceUsd / collateralPriceUsd
    /// @param bond The bond to make the query against.
    /// @param repayAmount The amount of hTokens to repay.
    /// @param collateral The collateral to make the query against.
    /// @return seizableCollateralAmount The amount of seizable collateral.
    function getSeizableCollateralAmount(
        IHToken bond,
        uint256 repayAmount,
        IErc20 collateral
    ) external view returns (uint256 seizableCollateralAmount);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Increases the debt of the caller and mints new hTokens.
    ///
    /// @dev Emits a {Borrow} event.
    ///
    /// Requirements:
    ///
    /// - The Fintroller must allow this action to be performed.
    /// - The maturity of the bond must be in the future.
    /// - The amount to borrow cannot be zero.
    /// - The new length of the bond list must be below the max bonds limit.
    /// - The new total amount of debt cannot exceed the debt ceiling.
    /// - The caller must not end up having a shortfall of liquidity.
    ///
    /// @param bond The address of the bond contract.
    /// @param borrowAmount The amount of hTokens to borrow and print into existence.
    function borrow(IHToken bond, uint256 borrowAmount) external;

    /// @notice Deposits collateral in the caller's account.
    ///
    /// @dev Emits a {DepositCollateral} event.
    ///
    /// Requirements:
    ///
    /// - The amount to deposit cannot be zero.
    /// - The Fintroller must allow this action to be performed.
    /// - The caller must have allowed this contract to spend `collateralAmount` tokens.
    /// - The new collateral amount cannot exceed the collateral ceiling.
    ///
    /// @param collateral The address of the collateral contract.
    /// @param depositAmount The amount of collateral to deposit.
    function depositCollateral(IErc20 collateral, uint256 depositAmount) external;

    /// @notice Repays the debt of the borrower and rewards the caller with a surplus of collateral.
    ///
    /// @dev Emits a {LiquidateBorrow} event.
    ///
    /// Requirements:
    ///
    /// - All from "repayBorrow".
    /// - The caller cannot be the same with the borrower.
    /// - The Fintroller must allow this action to be performed.
    /// - The borrower must have a shortfall of liquidity if the bond didn't mature.
    /// - The amount of seized collateral cannot be more than what the borrower has in the vault.
    ///
    /// @param bond The address of the bond contract.
    /// @param borrower The account to liquidate.
    /// @param repayAmount The amount of hTokens to repay.
    /// @param collateral The address of the collateral contract.
    function liquidateBorrow(
        address borrower,
        IHToken bond,
        uint256 repayAmount,
        IErc20 collateral
    ) external;

    /// @notice Erases the borrower's debt and takes the hTokens out of circulation.
    ///
    /// @dev Emits a {RepayBorrow} event.
    ///
    /// Requirements:
    ///
    /// - The amount to repay cannot be zero.
    /// - The Fintroller must allow this action to be performed.
    /// - The caller must have at least `repayAmount` hTokens.
    /// - The caller must have at least `repayAmount` debt.
    ///
    /// @param bond The address of the bond contract.
    /// @param repayAmount The amount of hTokens to repay.
    function repayBorrow(IHToken bond, uint256 repayAmount) external;

    /// @notice Erases the borrower's debt and takes the hTokens out of circulation.
    ///
    /// @dev Emits a {RepayBorrow} event.
    ///
    /// Requirements:
    /// - Same as the `repayBorrow` function, but here `borrower` is the account that must have at least
    /// `repayAmount` hTokens to repay the borrow.
    ///
    /// @param borrower The borrower account for which to repay the borrow.
    /// @param bond The address of the bond contract
    /// @param repayAmount The amount of hTokens to repay.
    function repayBorrowBehalf(
        address borrower,
        IHToken bond,
        uint256 repayAmount
    ) external;

    /// @notice Updates the oracle contract's address saved in storage.
    ///
    /// @dev Emits a {SetOracle} event.
    ///
    /// Requirements:
    ///
    /// - The caller must be the owner.
    /// - The new address cannot be the zero address.
    ///
    /// @param newOracle The new oracle contract.
    function setOracle(IChainlinkOperator newOracle) external;

    /// @notice Withdraws a portion or all of the collateral.
    ///
    /// @dev Emits a {WithdrawCollateral} event.
    ///
    /// Requirements:
    ///
    /// - The amount to withdraw cannot be zero.
    /// - There must be enough collateral in the vault.
    /// - The caller's account cannot fall below the collateral ratio.
    ///
    /// @param collateral The address of the collateral contract.
    /// @param withdrawAmount The amount of collateral to withdraw.
    function withdrawCollateral(IErc20 collateral, uint256 withdrawAmount) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

/// @title IOwnable
/// @author Paul Razvan Berg
/// @notice Contract module that provides a basic access control mechanism, where there is an
/// account (an owner) that can be granted exclusive access to specific functions.
///
/// By default, the owner account will be the one that deploys the contract. This can later be
/// changed with {transfer}.
///
/// This module is used through inheritance. It will make available the modifier `onlyOwner`,
/// which can be applied to your functions to restrict their use to the owner.
///
/// @dev Forked from OpenZeppelin
/// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/access/Ownable.sol
interface IOwnable {
    /// EVENTS ///

    /// @notice Emitted when ownership is transferred.
    /// @param oldOwner The address of the old owner.
    /// @param newOwner The address of the new owner.
    event TransferOwnership(address indexed oldOwner, address indexed newOwner);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Leaves the contract without owner, so it will not be possible to call `onlyOwner`
    /// functions anymore.
    ///
    /// WARNING: Doing this will leave the contract without an owner, thereby removing any
    /// functionality that is only available to the owner.
    ///
    /// Requirements:
    ///
    /// - The caller must be the owner.
    function _renounceOwnership() external;

    /// @notice Transfers the owner of the contract to a new account (`newOwner`). Can only be
    /// called by the current owner.
    /// @param newOwner The acount of the new owner.
    function _transferOwnership(address newOwner) external;

    /// CONSTANT FUNCTIONS ///

    /// @notice The address of the owner account or contract.
    /// @return The address of the owner.
    function owner() external view returns (address);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

/// @title IErc20
/// @author Paul Razvan Berg
/// @notice Implementation for the Erc20 standard.
///
/// We have followed general OpenZeppelin guidelines: functions revert instead of returning
/// `false` on failure. This behavior is nonetheless conventional and does not conflict with
/// the with the expectations of Erc20 applications.
///
/// Additionally, an {Approval} event is emitted on calls to {transferFrom}. This allows
/// applications to reconstruct the allowance for all accounts just by listening to said
/// events. Other implementations of the Erc may not emit these events, as it isn't
/// required by the specification.
///
/// Finally, the non-standard {decreaseAllowance} and {increaseAllowance} functions have been
/// added to mitigate the well-known issues around setting allowances.
///
/// @dev Forked from OpenZeppelin
/// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/token/ERC20/ERC20.sol
interface IErc20 {
    /// EVENTS ///

    /// @notice Emitted when an approval happens.
    /// @param owner The address of the owner of the tokens.
    /// @param spender The address of the spender.
    /// @param amount The maximum amount that can be spent.
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /// @notice Emitted when a transfer happens.
    /// @param from The account sending the tokens.
    /// @param to The account receiving the tokens.
    /// @param amount The amount of tokens transferred.
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// CONSTANT FUNCTIONS ///

    /// @notice Returns the remaining number of tokens that `spender` will be allowed to spend
    /// on behalf of `owner` through {transferFrom}. This is zero by default.
    ///
    /// @dev This value changes when {approve} or {transferFrom} are called.
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256);

    /// @notice Returns the number of decimals used to get its user representation.
    function decimals() external view returns (uint8);

    /// @notice Returns the name of the token.
    function name() external view returns (string memory);

    /// @notice Returns the symbol of the token, usually a shorter version of the name.
    function symbol() external view returns (string memory);

    /// @notice Returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
    ///
    /// @dev Emits an {Approval} event.
    ///
    /// IMPORTANT: Beware that changing an allowance with this method brings the risk that someone may
    /// use both the old and the new allowance by unfortunate transaction ordering. One possible solution
    /// to mitigate this race condition is to first reduce the spender's allowance to 0 and set the desired
    /// value afterwards: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    ///
    /// Requirements:
    ///
    /// - `spender` cannot be the zero address.
    ///
    /// @return a boolean value indicating whether the operation succeeded.
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Atomically decreases the allowance granted to `spender` by the caller.
    ///
    /// @dev Emits an {Approval} event indicating the updated allowance.
    ///
    /// This is an alternative to {approve} that can be used as a mitigation for problems described
    /// in {Erc20Interface-approve}.
    ///
    /// Requirements:
    ///
    /// - `spender` cannot be the zero address.
    /// - `spender` must have allowance for the caller of at least `subtractedAmount`.
    function decreaseAllowance(address spender, uint256 subtractedAmount) external returns (bool);

    /// @notice Atomically increases the allowance granted to `spender` by the caller.
    ///
    /// @dev Emits an {Approval} event indicating the updated allowance.
    ///
    /// This is an alternative to {approve} that can be used as a mitigation for the problems described above.
    ///
    /// Requirements:
    ///
    /// - `spender` cannot be the zero address.
    function increaseAllowance(address spender, uint256 addedAmount) external returns (bool);

    /// @notice Moves `amount` tokens from the caller's account to `recipient`.
    ///
    /// @dev Emits a {Transfer} event.
    ///
    /// Requirements:
    ///
    /// - `recipient` cannot be the zero address.
    /// - The caller must have a balance of at least `amount`.
    ///
    /// @return a boolean value indicating whether the operation succeeded.
    function transfer(address recipient, uint256 amount) external returns (bool);

    /// @notice Moves `amount` tokens from `sender` to `recipient` using the allowance mechanism. `amount`
    /// `is then deducted from the caller's allowance.
    ///
    /// @dev Emits a {Transfer} event and an {Approval} event indicating the updated allowance. This is
    /// not required by the Erc. See the note at the beginning of {Erc20}.
    ///
    /// Requirements:
    ///
    /// - `sender` and `recipient` cannot be the zero address.
    /// - `sender` must have a balance of at least `amount`.
    /// - The caller must have approed `sender` to spent at least `amount` tokens.
    ///
    /// @return a boolean value indicating whether the operation succeeded.
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: Unlicense
// solhint-disable func-name-mixedcase
pragma solidity >=0.8.4;

import "./IErc20.sol";

/// @title IErc20Permit
/// @author Paul Razvan Berg
/// @notice Extension of Erc20 that allows token holders to use their tokens without sending any
/// transactions by setting the allowance with a signature using the `permit` method, and then spend
/// them via `transferFrom`.
/// @dev See https://eips.ethereum.org/EIPS/eip-2612.
interface IErc20Permit is IErc20 {
    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Sets `amount` as the allowance of `spender` over `owner`'s tokens, assuming the latter's
    /// signed approval.
    ///
    /// @dev Emits an {Approval} event.
    ///
    /// IMPORTANT: The same issues Erc20 `approve` has related to transaction
    /// ordering also apply here.
    ///
    /// Requirements:
    ///
    /// - `owner` cannot be the zero address.
    /// - `spender` cannot be the zero address.
    /// - `deadline` must be a timestamp in the future.
    /// - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner` over the Eip712-formatted
    /// function arguments.
    /// - The signature must use `owner`'s current nonce.
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /// CONSTANT FUNCTIONS ///

    /// @notice The Eip712 domain's keccak256 hash.
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Provides replay protection.
    function nonces(address account) external view returns (uint256);

    /// @notice keccak256("Permit(address owner,address spender,uint256 amount,uint256 nonce,uint256 deadline)");
    function PERMIT_TYPEHASH() external view returns (bytes32);

    /// @notice Eip712 version of this implementation.
    function version() external view returns (string memory);
}

// SPDX-License-Identifier: Unlicense
// solhint-disable var-name-mixedcase
pragma solidity >=0.8.4;

import "./IErc20.sol";
import "../../access/IOwnable.sol";

/// @title IErc20Recover
/// @author Paul Razvan Berg
/// @notice Contract that gives the owner the ability to recover the Erc20 tokens that were sent
/// (accidentally, or not) to the contract.
interface IErc20Recover is IOwnable {
    /// EVENTS ///

    /// @notice Emitted when tokens are recovered.
    /// @param owner The address of the owner recoverring the tokens.
    /// @param token The address of the recovered token.
    /// @param recoverAmount The amount of recovered tokens.
    event Recover(address indexed owner, IErc20 token, uint256 recoverAmount);

    /// @notice Emitted when tokens are set as non-recoverable.
    /// @param owner The address of the owner calling the function.
    /// @param nonRecoverableTokens An array of token addresses.
    event SetNonRecoverableTokens(address indexed owner, IErc20[] nonRecoverableTokens);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Recover Erc20 tokens sent to this contract (by accident or otherwise).
    /// @dev Emits a {RecoverToken} event.
    ///
    /// Requirements:
    ///
    /// - The caller must be the owner.
    /// - The contract must be initialized.
    /// - The amount to recover cannot be zero.
    /// - The token to recover cannot be among the non-recoverable tokens.
    ///
    /// @param token The token to make the recover for.
    /// @param recoverAmount The uint256 amount to recover, specified in the token's decimal system.
    function _recover(IErc20 token, uint256 recoverAmount) external;

    /// @notice Sets the tokens that this contract cannot recover.
    ///
    /// @dev Emits a {SetNonRecoverableTokens} event.
    ///
    /// Requirements:
    ///
    /// - The caller must be the owner.
    /// - The contract cannot be already initialized.
    ///
    /// @param tokens The array of tokens to set as non-recoverable.
    function _setNonRecoverableTokens(IErc20[] calldata tokens) external;

    /// CONSTANT FUNCTIONS ///

    /// @notice The tokens that can be recovered cannot be in this mapping.
    function nonRecoverableTokens(uint256 index) external view returns (IErc20);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

/// @title Address
/// @author Paul Razvan Berg
/// @notice Collection of functions related to the address type.
/// @dev Forked from OpenZeppelin
/// https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v3.4.0/contracts/utils/Address.sol
library Address {
    /// @dev Returns true if `account` is a contract.
    ///
    /// IMPORTANT: It is unsafe to assume that an address for which this function returns false is an
    /// externally-owned account (EOA) and not a contract.
    ///
    /// Among others, `isContract` will return false for the following types of addresses:
    ///
    /// - An externally-owned account
    /// - A contract in construction
    /// - An address where a contract will be created
    /// - An address where a contract lived, but was destroyed
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`.
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.4;

import "@paulrberg/contracts/token/erc20/IErc20.sol";

import "./SFintrollerV1.sol";
import "../hToken/IHToken.sol";
import "../../access/OwnableUpgradeable.sol";

/// @notice IFintrollerV1
/// @author Hifi
/// @notice Controls the financial permissions and risk parameters for the Hifi protocol.
interface IFintrollerV1 is IOwnableUpgradeable {
    /// EVENTS ///

    /// @notice Emitted when a new bond is listed.
    /// @param owner The address of the contract owner.
    /// @param bond The newly listed bond.
    event ListBond(address indexed owner, IHToken indexed bond);

    /// @notice Emitted when a new collateral is listed.
    /// @param owner The address of the contract owner.
    /// @param collateral The newly listed collateral.
    event ListCollateral(address indexed owner, IErc20 indexed collateral);

    /// @notice Emitted when the borrow permission is updated.
    /// @param owner The address of the contract owner.
    /// @param bond The related HToken.
    /// @param state True if borrowing is allowed.
    event SetBorrowAllowed(address indexed owner, IHToken indexed bond, bool state);

    /// @notice Emitted when the collateral ceiling is updated.
    /// @param owner The address of the contract owner.
    /// @param collateral The related collateral.
    /// @param oldCollateralCeiling The old collateral ceiling.
    /// @param newCollateralCeiling The new collateral ceiling.
    event SetCollateralCeiling(
        address indexed owner,
        IErc20 indexed collateral,
        uint256 oldCollateralCeiling,
        uint256 newCollateralCeiling
    );

    /// @notice Emitted when the collateral ratio is updated.
    /// @param owner The address of the contract owner.
    /// @param collateral The related HToken.
    /// @param oldCollateralRatio The old collateral ratio.
    /// @param newCollateralRatio the new collateral ratio.
    event SetCollateralRatio(
        address indexed owner,
        IErc20 indexed collateral,
        uint256 oldCollateralRatio,
        uint256 newCollateralRatio
    );

    /// @notice Emitted when the debt ceiling for a bond is updated.
    /// @param owner The address of the contract owner.
    /// @param bond The related HToken.
    /// @param oldDebtCeiling The old debt ceiling.
    /// @param newDebtCeiling The new debt ceiling.
    event SetDebtCeiling(address indexed owner, IHToken indexed bond, uint256 oldDebtCeiling, uint256 newDebtCeiling);

    /// @notice Emitted when the deposit collateral permission is updated.
    /// @param owner The address of the contract owner.
    /// @param state True if depositing collateral is allowed.
    event SetDepositCollateralAllowed(address indexed owner, IErc20 indexed collateral, bool state);

    /// @notice Emitted when the liquidate borrow permission is updated.
    /// @param owner The address of the contract owner.
    /// @param bond The related HToken.
    /// @param state True if liquidating borrow is allowed.
    event SetLiquidateBorrowAllowed(address indexed owner, IHToken indexed bond, bool state);

    /// @notice Emitted when the collateral liquidation incentive is set.
    /// @param owner The address of the contract owner.
    /// @param collateral The related collateral.
    /// @param oldLiquidationIncentive The old liquidation incentive.
    /// @param newLiquidationIncentive The new liquidation incentive.
    event SetLiquidationIncentive(
        address indexed owner,
        IErc20 collateral,
        uint256 oldLiquidationIncentive,
        uint256 newLiquidationIncentive
    );

    /// @notice Emitted when a new max bonds value is set.
    /// @param owner The address indexed owner.
    /// @param oldMaxBonds The address of the old max bonds value.
    /// @param newMaxBonds The address of the new max bonds value.
    event SetMaxBonds(address indexed owner, uint256 oldMaxBonds, uint256 newMaxBonds);

    /// @notice Emitted when the redeem hTokens permission is updated.
    /// @param owner The address of the contract owner.
    /// @param bond The related HToken.
    /// @param state True if redeeming hTokens is allowed.
    event SetRedeemHTokensAllowed(address indexed owner, IHToken indexed bond, bool state);

    /// @notice Emitted when the repay borrow permission is updated.
    /// @param owner The address of the contract owner.
    /// @param bond The related HToken.
    /// @param state True if repaying borrow is allowed.
    event SetRepayBorrowAllowed(address indexed owner, IHToken indexed bond, bool state);

    /// @notice Emitted when the supply underlying permission is set.
    /// @param owner The address of the contract owner.
    /// @param bond The related HToken.
    /// @param state True if supplying underlying is allowed.
    event SetSupplyUnderlyingAllowed(address indexed owner, IHToken indexed bond, bool state);

    /// CONSTANT FUNCTIONS ///

    /// @notice Returns the Bond struct instance associated to the given address.
    /// @dev It is not an error to provide an invalid address.
    /// @param bond The address of the bond contract.
    /// @return The bond object.
    function getBond(IHToken bond) external view returns (SFintrollerV1.Bond memory);

    /// @notice Checks if the account should be allowed to borrow hTokens.
    /// @dev The bond must be listed.
    /// @param bond The bond to make the check against.
    /// @return bool true = allowed, false = not allowed.
    function getBorrowAllowed(IHToken bond) external view returns (bool);

    /// @notice Returns the Collateral struct instance associated to the given address.
    /// @dev It is not an error to provide an invalid address.
    /// @param collateral The address of the collateral contract.
    /// @return The collateral object.
    function getCollateral(IErc20 collateral) external view returns (SFintrollerV1.Collateral memory);

    /// @notice Returns the collateral ceiling.
    /// @dev It is not an error to provide an invalid address.
    /// @param collateral The address of the collateral contract.
    /// @return The collateral ceiling as a uint256, or zero if an invalid address was provided.
    function getCollateralCeiling(IErc20 collateral) external view returns (uint256);

    /// @notice Returns the collateral ratio.
    /// @dev It is not an error to provide an invalid address.
    /// @param collateral The address of the collateral contract.
    /// @return The collateral ratio, or zero if an invalid address was provided.
    function getCollateralRatio(IErc20 collateral) external view returns (uint256);

    /// @notice Returns the debt ceiling for the given bond.
    /// @dev It is not an error to provide an invalid address.
    /// @param bond The address of the bond contract.
    /// @return The debt ceiling as a uint256, or zero if an invalid address was provided.
    function getDebtCeiling(IHToken bond) external view returns (uint256);

    /// @notice Checks if collateral deposits are allowed.
    /// @dev The collateral must be listed.
    /// @param collateral The collateral contract to make the check against.
    /// @return bool true = allowed, false = not allowed.
    function getDepositCollateralAllowed(IErc20 collateral) external view returns (bool);

    /// @notice Returns the liquidation incentive of the given collateral.
    /// @dev It is not an error to provide an invalid address.
    /// @param collateral The address of the collateral contract.
    /// @return The liquidation incentive, or zero if an invalid address was provided.
    function getLiquidationIncentive(IErc20 collateral) external view returns (uint256);

    /// @notice Checks if the account should be allowed to liquidate hToken borrows.
    /// @dev The bond must be listed.
    /// @param bond The bond to make the check against.
    /// @return bool true = allowed, false = not allowed.
    function getLiquidateBorrowAllowed(IHToken bond) external view returns (bool);

    /// @notice Checks if the account should be allowed to repay borrows.
    /// @dev The bond must be listed.
    /// @param bond The bond to make the check against.
    /// @return bool true = allowed, false = not allowed.
    function getRepayBorrowAllowed(IHToken bond) external view returns (bool);

    /// @notice Checks if the bond is listed.
    /// @param bond The bond to make the check against.
    /// @return bool true = listed, otherwise not.
    function isBondListed(IHToken bond) external view returns (bool);

    /// @notice Checks if the collateral is listed.
    /// @param collateral The collateral to make the check against.
    /// @return bool true = listed, otherwise not.
    function isCollateralListed(IErc20 collateral) external view returns (bool);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Marks the bond as listed in this registry.
    ///
    /// @dev It is not an error to list a bond twice. Emits a {ListBond} event.
    ///
    /// Requirements:
    /// - The caller must be the owner.
    ///
    /// @param bond The hToken contract to list.
    function listBond(IHToken bond) external;

    /// @notice Marks the collateral as listed in this registry.
    ///
    /// @dev Emits a {ListCollateral} event. It is not an error to list a bond twice.
    ///
    /// Requirements:
    ///
    /// - The caller must be the owner.
    /// - The collateral must have between 1 and 18 decimals.
    ///
    /// @param collateral The collateral contract to list.
    function listCollateral(IErc20 collateral) external;

    /// @notice Updates the state of the permission accessed by the hToken before a borrow.
    ///
    /// @dev Emits a {SetBorrowAllowed} event.
    ///
    /// Requirements:
    ///
    /// - The caller must be the owner.
    /// - The bond must be listed.
    ///
    /// @param bond The bond to update the permission for.
    /// @param state The new state to put in storage.
    function setBorrowAllowed(IHToken bond, bool state) external;

    /// @notice Updates the collateral ceiling.
    ///
    /// @dev Emits a {SetCollateralCeiling} event.
    ///
    /// Requirements:
    ///
    /// - The caller must be the owner.
    /// - The collateral must be listed.
    ///
    /// @param collateral The collateral to update the ceiling for.
    /// @param newCollateralCeiling The new collateral ceiling.
    function setCollateralCeiling(IHToken collateral, uint256 newCollateralCeiling) external;

    /// @notice Updates the collateral ratio.
    ///
    /// @dev Emits a {SetCollateralRatio} event.
    ///
    /// Requirements:
    ///
    /// - The caller must be the owner.
    /// - The collateral must be listed.
    /// - The new collateral ratio cannot be higher than the maximum collateral ratio.
    /// - The new collateral ratio cannot be lower than the minimum collateral ratio.
    ///
    /// @param collateral The collateral to update the collateral ratio for.
    /// @param newCollateralRatio The new collateral ratio.
    function setCollateralRatio(IErc20 collateral, uint256 newCollateralRatio) external;

    /// @notice Updates the state of the permission accessed by the BalanceSheet before a collateral deposit.
    ///
    /// @dev Emits a {SetDepositCollateralAllowed} event.
    ///
    /// Requirements:
    /// - The caller must be the owner.
    ///
    /// @param collateral The collateral to update the permission for.
    /// @param state The new state to put in storage.
    function setDepositCollateralAllowed(IErc20 collateral, bool state) external;

    /// @notice Updates the debt ceiling for the given bond.
    ///
    /// @dev Emits a {SetDebtCeiling} event.
    ///
    /// Requirements:
    ///
    /// - The caller must be the owner.
    /// - The bond must be listed.
    /// - The debt ceiling cannot fall below the current total supply of hTokens.
    ///
    /// @param bond The bond to update the debt ceiling for.
    /// @param newDebtCeiling The new debt ceiling.
    function setDebtCeiling(IHToken bond, uint256 newDebtCeiling) external;

    /// @notice Updates the collateral liquidation incentive.
    ///
    /// @dev Emits a {SetLiquidationIncentive} event.
    ///
    /// Requirements:
    ///
    /// - The caller must be the owner.
    /// - The collateral must be listed.
    /// - The new liquidation incentive cannot be higher than the maximum liquidation incentive.
    /// - The new liquidation incentive cannot be lower than the minimum liquidation incentive.
    ///
    /// @param collateral The collateral to update the liquidation incentive for.
    /// @param newLiquidationIncentive The new liquidation incentive.
    function setLiquidationIncentive(IErc20 collateral, uint256 newLiquidationIncentive) external;

    /// @notice Updates the state of the permission accessed by the hToken before a liquidate borrow.
    ///
    /// @dev Emits a {SetLiquidateBorrowAllowed} event.
    ///
    /// Requirements:
    ///
    /// - The caller must be the owner.
    /// - The bond must be listed.
    ///
    /// @param bond The hToken contract to update the permission for.
    /// @param state The new state to put in storage.
    function setLiquidateBorrowAllowed(IHToken bond, bool state) external;

    /// @notice Sets max bonds value, which controls how many bond markets a single account can enter.
    ///
    /// @dev Emits a {SetMaxBonds} event.
    ///
    /// Requirements:
    /// - The caller must be the owner.
    ///
    /// @param newMaxBonds New max bonds value.
    function setMaxBonds(uint256 newMaxBonds) external;

    /// @notice Updates the state of the permission accessed by the hToken before a repay borrow.
    ///
    /// @dev Emits a {SetRepayBorrowAllowed} event.
    ///
    /// Requirements:
    ///
    /// - The caller must be the owner.
    /// - The bond must be listed.
    ///
    /// @param bond The hToken contract to update the permission for.
    /// @param state The new state to put in storage.
    function setRepayBorrowAllowed(IHToken bond, bool state) external;
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.4;

/// @title IOwnableUpgradeable
/// @author Hifi
interface IOwnableUpgradeable {
    /// EVENTS ///

    /// @notice Emitted when ownership is transferred.
    /// @param oldOwner The address of the old owner.
    /// @param newOwner The address of the new owner.
    event TransferOwnership(address indexed oldOwner, address indexed newOwner);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Leaves the contract without an owner, so it will not be possible to call `onlyOwner`
    /// functions anymore.
    ///
    /// WARNING: Doing this will leave the contract without an owner, thereby removing any
    /// functionality that is only available to the owner.
    ///
    /// Requirements:
    ///
    /// - The caller must be the owner.
    function _renounceOwnership() external;

    /// @notice Transfers the owner of the contract to a new account (`newOwner`). Can only be
    /// called by the current owner.
    /// @param newOwner The account of the new owner.
    function _transferOwnership(address newOwner) external;

    /// CONSTANT FUNCTIONS ///

    /// @notice The address of the owner account or contract.
    /// @return The address of the owner.
    function owner() external view returns (address);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.4;

import "@paulrberg/contracts/token/erc20/IErc20.sol";
import "@paulrberg/contracts/access/IOwnable.sol";

import "../external/chainlink/IAggregatorV3.sol";

/// @title IChainlinkOperator
/// @author Hifi
/// @notice Manages USD-quoted Chainlink price feeds.
interface IChainlinkOperator {
    /// STRUCTS ///

    struct Feed {
        IErc20 asset;
        IAggregatorV3 id;
        bool isSet;
    }

    /// EVENTS ///

    /// @notice Emitted when a feed is deleted.
    /// @param asset The related asset.
    /// @param feed The related feed.
    event DeleteFeed(IErc20 indexed asset, IAggregatorV3 indexed feed);

    /// @notice Emitted when a feed is set.
    /// @param asset The related asset.
    /// @param feed The related feed.
    event SetFeed(IErc20 indexed asset, IAggregatorV3 indexed feed);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Deletes a previously set Chainlink price feed.
    ///
    /// @dev Emits a {DeleteFeed} event.
    ///
    /// Requirements:
    ///
    /// - The caller must be the owner.
    /// - The feed must have been previously set.
    ///
    /// @param symbol The Erc20 symbol of the asset to delete the feed for.
    function deleteFeed(string memory symbol) external;

    /// @notice Sets a Chainlink price feed.
    ///
    /// @dev It is not an error to set a feed twice. Emits a {SetFeed} event.
    ///
    /// Requirements:
    ///
    /// - The caller must be the owner.
    /// - The number of decimals of the feed must be 8.
    ///
    /// @param asset The address of the Erc20 contract for which to get the price.
    /// @param feed The address of the Chainlink price feed contract.
    function setFeed(IErc20 asset, IAggregatorV3 feed) external;

    /// CONSTANT FUNCTIONS ///

    /// @notice Gets the official feed for a symbol.
    /// @param symbol The symbol to return the feed for.
    /// @return (address asset, address id, bool isSet).
    function getFeed(string memory symbol)
        external
        view
        returns (
            IErc20,
            IAggregatorV3,
            bool
        );

    /// @notice Gets the official price for a symbol and adjusts it have 18 decimals instead of the
    /// format used by Chainlink, which has 8 decimals.
    ///
    /// @dev Requirements:
    /// - The normalized price cannot overflow.
    ///
    /// @param symbol The Erc20 symbol of the token for which to query the price.
    /// @return The normalized price.
    function getNormalizedPrice(string memory symbol) external view returns (uint256);

    /// @notice Gets the official price for a symbol in the default format used by Chainlink, which
    /// has 8 decimals.
    ///
    /// @dev Requirements:
    ///
    /// - The feed must have been previously set.
    /// - The price returned by the oracle cannot be zero.
    ///
    /// @param symbol The symbol to fetch the price for.
    /// @return Price denominated in USD, with 8 decimals.
    function getPrice(string memory symbol) external view returns (uint256);

    /// @notice Chainlink price precision for USD-quoted data.
    function pricePrecision() external view returns (uint256);

    /// @notice The ratio between normalized precision (1e18) and the Chainlink price precision (1e8).
    function pricePrecisionScalar() external view returns (uint256);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.4;

import "@paulrberg/contracts/token/erc20/IErc20.sol";

import "../hToken/IHToken.sol";

/// @notice SFintrollerV1
/// @author Hifi
abstract contract SFintrollerV1 {
    /// STRUCTS ///
    struct Bond {
        uint256 debtCeiling;
        bool isBorrowAllowed;
        bool isLiquidateBorrowAllowed;
        bool isListed;
        bool isRedeemHTokenAllowed;
        bool isRepayBorrowAllowed;
        bool isSupplyUnderlyingAllowed;
    }

    struct Collateral {
        uint256 ceiling;
        uint256 ratio;
        uint256 liquidationIncentive;
        bool isDepositCollateralAllowed;
        bool isListed;
    }

    /// PUBLIC STORAGE ///

    /// @notice The maximum number of bond markets a single account can enter.
    uint256 public maxBonds;

    /// INTERNAL STORAGE ///

    /// @dev The threshold below which the collateral ratio cannot be set, equivalent to 100%.
    uint256 internal constant COLLATERAL_RATIO_LOWER_BOUND = 1.0e18;

    /// @dev The threshold above which the collateral ratio cannot be set, equivalent to 10,000%.
    uint256 internal constant COLLATERAL_RATIO_UPPER_BOUND = 1.0e20;

    /// @dev The default collateral ratio set when a new bond is listed, equivalent to 150%.
    uint256 internal constant DEFAULT_COLLATERAL_RATIO = 1.5e18;

    /// @dev The default liquidation incentive set when a new bond is listed, equivalent to 110%.
    uint256 internal constant DEFAULT_LIQUIDATION_INCENTIVE = 1.1e18;

    /// @dev The default maximum number of bond markets a single account can enter.
    uint256 internal constant DEFAULT_MAX_BONDS = 10;

    /// @dev The threshold below which the liquidation incentive cannot be set, equivalent to 100%.
    uint256 internal constant LIQUIDATION_INCENTIVE_LOWER_BOUND = 1.0e18;

    /// @dev The threshold above which the liquidation incentive cannot be set, equivalent to 150%.
    uint256 internal constant LIQUIDATION_INCENTIVE_UPPER_BOUND = 1.5e18;

    /// @notice Maps hTokens to Bond structs.
    mapping(IHToken => Bond) internal bonds;

    /// @notice Maps IErc20s to Collateral structs.
    mapping(IErc20 => Collateral) internal collaterals;
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./IOwnableUpgradeable.sol";

/// @notice Emitted when the caller is not the owner.
error OwnableUpgradeable__NotOwner(address owner, address caller);

/// @notice Emitted when setting the owner to the zero address.
error OwnableUpgradeable__OwnerZeroAddress();

/// @title OwnableUpgradeable
/// @author Hifi
/// @dev Forked from OpenZeppelin
/// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/access/Ownable.sol
contract OwnableUpgradeable is
    IOwnableUpgradeable, // no dependency
    Initializable // no dependency
{
    /// PUBLIC STORAGE ///

    /// @inheritdoc IOwnableUpgradeable
    address public override owner;

    /// MODIFIERS ///

    /// @notice Throws if called by any account other than the owner.
    modifier onlyOwner() {
        if (owner != msg.sender) {
            revert OwnableUpgradeable__NotOwner(owner, msg.sender);
        }
        _;
    }

    /// INITIALIZER ///

    /// @notice The upgradeability variant of the contract constructor.
    /// @dev Sets the deployer as the initial owner.
    function __OwnableUpgradeable__init() public initializer {
        owner = msg.sender;
        emit TransferOwnership(address(0), msg.sender);
    }

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc IOwnableUpgradeable
    function _renounceOwnership() external virtual override onlyOwner {
        emit TransferOwnership(owner, address(0));
        owner = address(0);
    }

    /// @inheritdoc IOwnableUpgradeable
    function _transferOwnership(address newOwner) external virtual override onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableUpgradeable__OwnerZeroAddress();
        }
        emit TransferOwnership(owner, newOwner);
        owner = newOwner;
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

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity >=0.8.4;

/// @title IAggregatorV3
/// @author Hifi
/// @dev Forked from Chainlink
/// github.com/smartcontractkit/chainlink/blob/v0.9.9/evm-contracts/src/v0.7/interfaces/IAggregatorV3.sol
interface IAggregatorV3 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    /// getRoundData and latestRoundData should both raise "No data present" if they do not have
    /// data to report, instead of returning unset values which could be misinterpreted as
    /// actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

