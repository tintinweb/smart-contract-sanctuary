/**
 *Submitted for verification at Etherscan.io on 2021-03-05
*/

pragma solidity ^0.8.0;

abstract contract AdminStorage {
    /// @notice The address of the administrator account or contract.
    address public admin;
}



pragma solidity ^0.8.0;

/// @title AdminInterface
/// @author Paul Razvan Berg
abstract contract AdminInterface is AdminStorage {
    /// NON-CONSTANT FUNCTIONS ///
    function _renounceAdmin() external virtual;

    function _transferAdmin(address newAdmin) external virtual;

    /// EVENTS ///
    event TransferAdmin(address indexed oldAdmin, address indexed newAdmin);
}


// File contracts/access/Admin.sol


pragma solidity ^0.8.0;

/// @title Admin
/// @author Paul Razvan Berg
/// @notice Contract module which provides a basic access control mechanism, where there is an
/// account (an admin) that can be granted exclusive access to specific functions.
///
/// By default, the admin account will be the one that deploys the contract. This can later be
/// changed with {transferAdmin}.
///
/// This module is used through inheritance. It will make available the modifier `onlyAdmin`,
/// which can be applied to your functions to restrict their use to the admin.
///
/// @dev Forked from OpenZeppelin
/// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/access/Ownable.sol
abstract contract Admin is AdminInterface {
    /// @notice Throws if called by any account other than the admin.
    modifier onlyAdmin() {
        require(admin == msg.sender, "ERR_NOT_ADMIN");
        _;
    }

    /// @notice Initializes the contract setting the deployer as the initial admin.
    constructor() {
        address msgSender = msg.sender;
        admin = msgSender;
        emit TransferAdmin(address(0), msgSender);
    }

    /// @notice Leaves the contract without admin, so it will not be possible to call `onlyAdmin`
    /// functions anymore.
    ///
    /// WARNING: Doing this will leave the contract without an admin, thereby removing any
    /// functionality that is only available to the admin.
    ///
    /// Requirements:
    ///
    /// - The caller must be the administrator.
    function _renounceAdmin() external virtual override onlyAdmin {
        emit TransferAdmin(admin, address(0));
        admin = address(0);
    }

    /// @notice Transfers the admin of the contract to a new account (`newAdmin`). Can only be
    /// called by the current admin.
    /// @param newAdmin The acount of the new admin.
    function _transferAdmin(address newAdmin) external virtual override onlyAdmin {
        require(newAdmin != address(0), "ERR_SET_ADMIN_ZERO_ADDRESS");
        emit TransferAdmin(admin, newAdmin);
        admin = newAdmin;
    }
}


// File contracts/access/OrchestratableStorage.sol


pragma solidity ^0.8.0;

abstract contract OrchestratableStorage {
    /// @notice The address of the conductor account or contract.
    address public conductor;

    /// @notice The orchestrated contract functions.
    mapping(address => mapping(bytes4 => bool)) public orchestration;
}


// File contracts/access/OrchestratableInterface.sol


pragma solidity ^0.8.0;

/// @title OrchestratableInterface
/// @author Paul Razvan Berg
abstract contract OrchestratableInterface is OrchestratableStorage {
    /// NON-CONSTANTS FUNCTIONS ///
    function _orchestrate(address account, bytes4 signature) external virtual;

    /// EVENTS ///
    event GrantAccess(address access);

    event TransferConductor(address indexed oldConductor, address indexed newConductor);
}


// File contracts/access/Orchestratable.sol


pragma solidity ^0.8.0;


/// @author Paul Razvan Berg
/// @notice Orchestrated static access control between multiple contracts.
///
/// This should be used as a parent contract of any contract that needs to restrict access to some methods, which
/// should be marked with the `onlyOrchestrated` modifier.
///
/// During deployment, the contract deployer (`conductor`) can register any contracts that have privileged access
/// by calling `orchestrate`.
///
/// Once deployment is completed, `conductor` should call `transferConductor(address(0))` to avoid any more
/// contracts ever gaining privileged access.
///
/// @dev Forked from Alberto Cuesta Cañada
/// https://github.com/albertocuestacanada/Orchestrated/blob/b0adb21/contracts/Orchestrated.sol
abstract contract Orchestratable is
    OrchestratableInterface, /// one dependency
    Admin /// two dependencies
{
    /// @notice Restricts usage to authorized accounts.
    modifier onlyOrchestrated() {
        require(orchestration[msg.sender][msg.sig], "ERR_NOT_ORCHESTRATED");
        _;
    }

    /// @notice Adds new orchestrated address.
    /// @param account Address of EOA or contract to give access to this contract.
    /// @param signature bytes4 signature of the function to be given orchestrated access to.
    function _orchestrate(address account, bytes4 signature) external override onlyAdmin {
        orchestration[account][signature] = true;
        emit GrantAccess(account);
    }
}


// File contracts/math/ExponentialStorage.sol


pragma solidity ^0.8.0;

/// @title ExponentialStorage
/// @author Paul Razvan Berg
/// @notice The storage interface ancillary to an Exponential contract.
abstract contract ExponentialStorage {
    struct Exp {
        uint256 mantissa;
    }

    /// @dev In Exponential denomination, 1e18 is 1.
    uint256 internal constant expScale = 1e18;
    uint256 internal constant halfExpScale = expScale / 2;
    uint256 internal constant mantissaOne = expScale;
}


// File contracts/math/Exponential.sol


pragma solidity ^0.8.0;

/// @title Exponential module for storing fixed-precision decimals.
/// @author Paul Razvan Berg
/// @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
/// Therefore, if we wanted to store the 5.1, mantissa would store 5.1e18: `Exp({mantissa: 5100000000000000000})`.
/// @dev Forked from Compound
/// https://github.com/compound-finance/compound-protocol/blob/v2.8.1/contracts/Exponential.sol
abstract contract Exponential is ExponentialStorage {
    /// @dev Adds two exponentials, returning a new exponential.
    function addExp(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
        uint256 result = a.mantissa + b.mantissa;
        return Exp({ mantissa: result });
    }

    /// @dev Divides two exponentials, returning a new exponential.
    /// (a/scale) / (b/scale) = (a/scale) * (scale/b) = a/b.
    function divExp(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
        uint256 scaledNumerator = a.mantissa * expScale;
        uint256 rational = scaledNumerator / b.mantissa;
        return Exp({ mantissa: rational });
    }

    /// @dev Multiplies two exponentials, returning a new exponential.
    function mulExp(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
        uint256 doubleScaledProduct = a.mantissa * b.mantissa;

        // We add half the scale before dividing so that we get rounding instead of truncation.
        // See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
        // Without this change, a result like 6.6...e-19 will be truncated to 0 instead of being rounded to 1e-18.
        uint256 doubleScaledProductWithHalfScale = halfExpScale + doubleScaledProduct;

        uint256 product = doubleScaledProductWithHalfScale / expScale;
        return Exp({ mantissa: product });
    }

    /// @dev Multiplies three exponentials, returning a new exponential.
    function mulExp3(
        Exp memory a,
        Exp memory b,
        Exp memory c
    ) internal pure returns (Exp memory) {
        Exp memory ab = mulExp(a, b);
        return mulExp(ab, c);
    }

    /// @dev Subtracts two exponentials, returning a new exponential.
    function subExp(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
        uint256 result = a.mantissa - b.mantissa;
        return Exp({ mantissa: result });
    }
}


// File contracts/token/erc20/Erc20Storage.sol


pragma solidity ^0.8.0;

/// @title Erc20Storage
/// @author Paul Razvan Berg
/// @notice The storage interface of an Erc20 contract.
abstract contract Erc20Storage {
    /// @notice Returns the number of decimals used to get its user representation.
    uint8 public decimals;

    /// @notice Returns the name of the token.
    string public name;

    /// @notice Returns the symbol of the token, usually a shorter version of the name.
    string public symbol;

    /// @notice Returns the amount of tokens in existence.
    uint256 public totalSupply;

    mapping(address => mapping(address => uint256)) internal allowances;

    mapping(address => uint256) internal balances;
}


// File contracts/token/erc20/Erc20Interface.sol


pragma solidity ^0.8.0;

/// @title Erc20Interface
/// @author Paul Razvan Berg
/// @notice Contract interface adhering to the Erc20 standard.
/// @dev Forked from OpenZeppelin
/// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.0/contracts/token/ERC20/IERC20.sol
abstract contract Erc20Interface is Erc20Storage {
    /// CONSTANT FUNCTIONS ///
    function allowance(address owner, address spender) external view virtual returns (uint256);

    function balanceOf(address account) external view virtual returns (uint256);

    /// NON-CONSTANT FUNCTIONS ///
    function approve(address spender, uint256 amount) external virtual returns (bool);

    function transfer(address recipient, uint256 amount) external virtual returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual returns (bool);

    /// EVENTS ///
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event Burn(address indexed holder, uint256 burnAmount);

    event Mint(address indexed beneficiary, uint256 mintAmount);

    event Transfer(address indexed from, address indexed to, uint256 amount);
}


// File contracts/token/erc20/Erc20RecoverStorage.sol


pragma solidity ^0.8.0;

abstract contract Erc20RecoverStorage {
    /// @notice The tokens that can be recovered cannot be in this mapping.
    Erc20Interface[] public nonRecoverableTokens;

    /// @dev A flag that signals whether the the non-recoverable tokens were set or not.
    bool internal isRecoverInitialized;
}


// File contracts/token/erc20/Erc20RecoverInterface.sol


pragma solidity ^0.8.0;


abstract contract Erc20RecoverInterface is Erc20RecoverStorage {
    /// NON-CONSTANT FUNCTIONS ///
    function _recover(Erc20Interface token, uint256 recoverAmount) external virtual;

    function _setNonRecoverableTokens(Erc20Interface[] calldata tokens) external virtual;

    /// EVENTS ///
    event Recover(address indexed admin, Erc20Interface token, uint256 recoverAmount);
    event SetNonRecoverableTokens(address indexed admin, Erc20Interface[] nonRecoverableTokens);
}


// File contracts/utils/Address.sol


pragma solidity ^0.8.0;

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


// File contracts/token/erc20/SafeErc20.sol


pragma solidity ^0.8.0;


/// @title SafeErc20.sol
/// @author Paul Razvan Berg
/// @notice Wraps around Erc20 operations that throw on failure (when the token contract
/// returns false). Tokens that return no value (and instead revert or throw
/// on failure) are also supported, non-reverting calls are assumed to be successful.
///
/// To use this library you can add a `using SafeErc20 for Erc20Interface;` statement to your contract,
/// which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
///
/// @dev Forked from OpenZeppelin
/// https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v3.4.0/contracts/utils/Address.sol
library SafeErc20 {
    using Address for address;

    /// INTERNAL FUNCTIONS ///

    function safeTransfer(
        Erc20Interface token,
        address to,
        uint256 amount
    ) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, amount));
    }

    function safeTransferFrom(
        Erc20Interface token,
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
    function callOptionalReturn(Erc20Interface token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.
        bytes memory returndata = functionCall(address(token), data, "ERR_SAFE_ERC20_LOW_LEVEL_CALL");
        if (returndata.length > 0) {
            // Return data is optional.
            require(abi.decode(returndata, (bool)), "ERR_SAFE_ERC20_ERC20_OPERATION");
        }
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(target.isContract(), "ERR_SAFE_ERC20_CALL_TO_NON_CONTRACT");

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


// File contracts/token/erc20/Erc20Recover.sol


pragma solidity ^0.8.0;




/// @title Erc20Recover
/// @author Paul Razvan Berg
/// @notice Gives the administrator the ability to recover the Erc20 tokens that
/// had been sent (accidentally, or not) to the contract.
abstract contract Erc20Recover is
    Erc20RecoverInterface, /// one dependency
    Admin /// two dependencies
{
    using SafeErc20 for Erc20Interface;

    /// @notice Sets the tokens that this contract cannot recover.
    ///
    /// @dev Emits a {SetNonRecoverableTokens} event.
    ///
    /// Requirements:
    ///
    /// - The caller must be the administrator.
    /// - The contract cannot be already initialized.
    ///
    /// @param tokens The array of tokens to set as non-recoverable.
    function _setNonRecoverableTokens(Erc20Interface[] calldata tokens) external override onlyAdmin {
        // Checks
        require(isRecoverInitialized == false, "ERR_INITALIZED");

        // Iterate over the token list, sanity check each and update the mapping.
        uint256 length = tokens.length;
        for (uint256 i = 0; i < length; i += 1) {
            tokens[i].symbol();
            nonRecoverableTokens.push(tokens[i]);
        }

        // Effects: prevent this function from ever being called again.
        isRecoverInitialized = true;

        emit SetNonRecoverableTokens(admin, tokens);
    }

    /// @notice Recover Erc20 tokens sent to this contract (by accident or otherwise).
    /// @dev Emits a {RecoverToken} event.
    ///
    /// Requirements:
    ///
    /// - The caller must be the administrator.
    /// - The contract must be initialized.
    /// - The amount to recover cannot be zero.
    /// - The token to recover cannot be among the non-recoverable tokens.
    ///
    /// @param token The token to make the recover for.
    /// @param recoverAmount The uint256 amount to recover, specified in the token's decimal system.
    function _recover(Erc20Interface token, uint256 recoverAmount) external override onlyAdmin {
        // Checks
        require(isRecoverInitialized == true, "ERR_NOT_INITALIZED");
        require(recoverAmount > 0, "ERR_RECOVER_ZERO");

        bytes32 tokenSymbolHash = keccak256(bytes(token.symbol()));
        uint256 length = nonRecoverableTokens.length;

        // We iterate over the non-recoverable token array and check that:
        //
        //   1. The addresses of the tokens are not the same
        //   2. The symbols of the tokens are not the same
        //
        // It is true that the second check may lead to a false positive, but
        // there is no better way to fend off against proxied tokens.
        for (uint256 i = 0; i < length; i += 1) {
            require(
                address(token) != address(nonRecoverableTokens[i]) &&
                    tokenSymbolHash != keccak256(bytes(nonRecoverableTokens[i].symbol())),
                "ERR_RECOVER_NON_RECOVERABLE_TOKEN"
            );
        }

        // Interactions
        token.safeTransfer(admin, recoverAmount);

        emit Recover(admin, token, recoverAmount);
    }
}


// File contracts/test/GodModeErc20Recover.sol


// solhint-disable func-name-mixedcase
pragma solidity ^0.8.0;

/// @title GodModeErc20Recover
/// @author Paul Razvan Berg
/// @dev Strictly for test purposes. Do not use in production.
contract GodModeErc20Recover is Erc20Recover {
    function __godMode_getIsRecoverInitialized() external view returns (bool) {
        return isRecoverInitialized;
    }

    function __godMode_setIsRecoverInitialized(bool state) external {
        isRecoverInitialized = state;
    }
}


// File contracts/token/erc20/Erc20.sol


pragma solidity ^0.8.0;

/// @title Erc20
/// @author Paul Razvan Berg
/// @notice Implementation of the {Erc20Interface} interface.
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
///@dev Forked from OpenZeppelin
///https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.2.0/contracts/token/Erc20/Erc20.sol
contract Erc20 is Erc20Interface {
    /// @notice All three of these values are immutable: they can only be set once during construction.
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

    /// CONSTANT FUNCTIONS ///

    /// @notice Returns the remaining number of tokens that `spender` will be allowed to spend
    /// on behalf of `owner` through {transferFrom}. This is zero by default.
    ///
    /// This value changes when {approve} or {transferFrom} are called.
    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return allowances[owner][spender];
    }

    /// @notice Returns the amount of tokens owned by `account`.
    function balanceOf(address account) public view virtual override returns (uint256) {
        return balances[account];
    }

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
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        approveInternal(msg.sender, spender, amount);
        return true;
    }

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
    /// - `spender` must have allowance for the caller of at least
    /// `subtractedValue`.
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        uint256 newAllowance = allowances[msg.sender][spender] - subtractedValue;
        approveInternal(msg.sender, spender, newAllowance);
        return true;
    }

    /// @notice Atomically increases the allowance granted to `spender` by the caller.
    ///
    /// @dev Emits an {Approval} event indicating the updated allowance.
    ///
    /// This is an alternative to {approve} that can be used as a mitigation for the problems
    /// described above.
    ///
    /// Requirements:
    ///
    /// - `spender` cannot be the zero address.
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        uint256 newAllowance = allowances[msg.sender][spender] + addedValue;
        approveInternal(msg.sender, spender, newAllowance);
        return true;
    }

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
    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        transferInternal(msg.sender, recipient, amount);
        return true;
    }

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
    ) external virtual override returns (bool) {
        transferInternal(sender, recipient, amount);

        uint256 currentAllowance = allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERR_ERC20_TRANSFER_FROM_INSUFFICIENT_ALLOWANCE");
        approveInternal(sender, msg.sender, currentAllowance);
        return true;
    }

    /// INTERNAL FUNCTIONS ///

    /// @notice Sets `amount` as the allowance of `spender` over the `owner`s tokens.
    ///
    /// @dev Emits an {Approval} event.
    ///
    /// This is internal function is equivalent to `approve`, and can be used to e.g. set automatic
    /// allowances for certain subsystems, etc.
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
        require(owner != address(0), "ERR_ERC20_APPROVE_FROM_ZERO_ADDRESS");
        require(spender != address(0), "ERR_ERC20_APPROVE_TO_ZERO_ADDRESS");

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
        require(holder != address(0), "ERR_ERC20_BURN_ZERO_ADDRESS");

        uint256 accountBalance = balances[holder];
        require(accountBalance >= burnAmount, "ERR_ERC20_BURN_BALANCE_UNDERFLOW");

        // Burn the tokens.
        balances[holder] = accountBalance - burnAmount;

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
        require(beneficiary != address(0), "ERR_ERC20_MINT_ZERO_ADDRESS");

        /// Mint the new tokens.
        balances[beneficiary] += mintAmount;

        /// Increase the total supply.
        totalSupply += mintAmount;

        emit Transfer(address(0), beneficiary, mintAmount);
    }

    /// @notice Moves `amount` tokens from `sender` to `recipient`.
    ///
    /// @dev This is internal function is equivalent to {transfer}, and can be used to e.g. implement
    /// automatic token fees, slashing mechanisms, etc.
    ///
    /// Emits a {Transfer} event.
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
        require(sender != address(0), "ERR_ERC20_TRANSFER_FROM_ZERO_ADDRESS");
        require(recipient != address(0), "ERR_ERC20_TRANSFER_TO_ZERO_ADDRESS");

        uint256 senderBalance = balances[sender];
        require(senderBalance >= amount, "ERR_ERC20_TRANSFER_INSUFFICIENT_BALANCE");
        balances[sender] = senderBalance - amount;
        balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }
}


// File contracts/token/erc20/Erc20PermitStorage.sol


// solhint-disable var-name-mixedcase
pragma solidity ^0.8.0;

/// @notice Erc20PermitStorage
/// @author Paul Razvan Berg
abstract contract Erc20PermitStorage {
    /// @notice The Eip712 domain's keccak256 hash.
    bytes32 public DOMAIN_SEPARATOR;

    /// @notice keccak256("Permit(address owner,address spender,uint256 amount,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0xfc77c2b9d30fe91687fd39abb7d16fcdfe1472d065740051ab8b13e4bf4a617f;

    /// @notice Provides replay protection.
    mapping(address => uint256) public nonces;

    /// @notice Eip712 version of this implementation.
    string public constant version = "1";
}


// File contracts/token/erc20/Erc20PermitInterface.sol


// solhint-disable var-name-mixedcase
pragma solidity ^0.8.0;

/// @notice Erc20PermitInterface
/// @author Paul Razvan Berg
abstract contract Erc20PermitInterface is Erc20PermitStorage {
    /// NON-CONSTANT FUNCTIONS ///
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual;
}


// File contracts/token/erc20/Erc20Permit.sol


pragma solidity ^0.8.0;


/// @title Erc20Permit
/// @author Paul Razvan Berg
/// @notice Extension of Erc20 that allows token holders to use their tokens without sending any
/// transactions by setting the allowance with a signature using the `permit` method, and then spend
/// them via `transferFrom`.
/// @dev See https://eips.ethereum.org/EIPS/eip-2612.
contract Erc20Permit is
    Erc20PermitInterface, /// one dependency
    Erc20 /// two dependencies
{
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) Erc20(name_, symbol_, decimals_) {
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
    ) external override {
        require(owner != address(0), "ERR_ERC20_PERMIT_OWNER_ZERO_ADDRESS");
        require(spender != address(0), "ERR_ERC20_PERMIT_SPENDER_ZERO_ADDRESS");
        require(deadline >= block.timestamp, "ERR_ERC20_PERMIT_EXPIRED");

        // It's safe to use the "+" operator here because the nonce cannot realistically overflow, ever.
        bytes32 hashStruct = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, amount, nonces[owner]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashStruct));
        address recoveredOwner = ecrecover(digest, v, r, s);

        require(recoveredOwner != address(0), "ERR_ERC20_PERMIT_RECOVERED_OWNER_ZERO_ADDRESS");
        require(recoveredOwner == owner, "ERR_ERC20_PERMIT_INVALID_SIGNATURE");

        approveInternal(owner, spender, amount);
    }
}


// File contracts/token/erc20/GodModeErc20.sol

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.0;

/// @title GodModeErc20
/// @author Paul Razvan Berg
/// @notice Implementation that allows anyone to mint or burn tokens belonging to any address.
/// @dev Strictly for test purposes.
contract GodModeErc20 is Erc20 {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) Erc20(name_, symbol_, decimals_) {} // solhint-disable-line no-empty-blocks

    /// @notice Destroys `burnAmount` tokens from `holder`, reducing the token supply.
    /// @param holder The account whose tokens to burn.
    /// @param burnAmount The amount of fyTokens to destroy.
    function burn(address holder, uint256 burnAmount) external {
        burnInternal(holder, burnAmount);
    }

    /// @notice Prints new tokens into existence and assigns them to `beneficiary`, increasing the
    /// total supply.
    /// @param beneficiary The account for which to mint the tokens.
    /// @param mintAmount The amount of fyTokens to print into existence.
    function mint(address beneficiary, uint256 mintAmount) external {
        mintInternal(beneficiary, mintAmount);
    }
}


// File contracts/token/erc20/NonStandardErc20.sol


pragma solidity ^0.8.0;

/// @title NonStandardErc20
/// @author Paul Razvan Berg
/// @notice An implementation of Erc20 that does not return a boolean on `transfer` and `transferFrom`.
/// @dev Strictly for test purposes. Do not use in production.
/// https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
contract NonStandardErc20 {
    uint8 public decimals;

    string public name;

    string public symbol;

    uint256 public totalSupply;

    mapping(address => mapping(address => uint256)) internal allowances;

    mapping(address => uint256) internal balances;

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return allowances[owner][spender];
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        approveInternal(msg.sender, spender, amount);
        return true;
    }

    /// @dev This function does not return a value, in violation of the Erc20 specification.
    function transfer(address recipient, uint256 amount) external {
        transferInternal(msg.sender, recipient, amount);
    }

    /// @dev This function does not return a value, in violation of the Erc20 specification.
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external {
        transferInternal(sender, recipient, amount);
        approveInternal(sender, msg.sender, allowances[sender][msg.sender] - amount);
    }

    function transferInternal(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        balances[sender] = balances[sender] - amount;
        balances[recipient] = balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
    }

    function approveInternal(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}


// File contracts/utils/ReentrancyGuard.sol


pragma solidity ^0.8.0;

/// @title ReentrancyGuard
/// @author Paul Razvan Berg
/// @notice Contract module that helps prevent reentrant calls to a function.
///
/// Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier available, which can
/// be applied to functions to make sure there are no nested (reentrant) calls to them.
///
/// Note that because there is a single `nonReentrant` guard, functions marked as `nonReentrant` may
/// not call one another. This can be worked around by making those functions `private`, and then adding
/// `external` `nonReentrant` entry points to them.
///
/// @dev Forked from OpenZeppelin
/// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.1.0/contracts/math/ReentrancyGuard.sol
abstract contract ReentrancyGuard {
    bool private notEntered;

    /// Storing an initial non-zero value makes deployment a bit more expensive
    /// but in exchange the refund on every call to nonReentrant will be lower
    /// in amount. Since refunds are capped to a percetange of the total
    /// transaction's gas, it is best to keep them low in cases like this
    /// one, to increase the likelihood of the full refund coming into effect.
    constructor() {
        notEntered = true;
    }

    /// @notice Prevents a contract from calling itself, directly or indirectly.
    /// @dev Calling a `nonReentrant` function from another `nonReentrant` function
    /// is not supported. It is possible to prevent this from happening by making
    /// the `nonReentrant` function external, and make it call a `private`
    /// function that does the actual work.
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true.
        require(notEntered, "ERR_REENTRANT_CALL");

        // Any calls to nonReentrant after this point will fail.
        notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200).
        notEntered = true;
    }
}