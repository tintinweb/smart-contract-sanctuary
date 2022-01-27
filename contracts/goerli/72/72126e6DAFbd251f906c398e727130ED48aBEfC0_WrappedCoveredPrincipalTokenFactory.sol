// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.0;

import { WrappedCoveredPrincipalToken, EnumerableSet } from "./WrappedCoveredPrincipalToken.sol";

/// @author Element Finance
/// @title WrappedCoveredPrincipalTokenFactory
contract WrappedCoveredPrincipalTokenFactory {
    using EnumerableSet for EnumerableSet.AddressSet;

    // Enumerable list of wrapped tokens that get created from the factory.
    EnumerableSet.AddressSet private _WrappedCoveredPrincipalTokens;

    // Tranche factory address for Tranche contract address derivation
    address internal immutable _trancheFactory;
    // Tranche bytecode hash for Tranche contract address derivation.
    // This is constant as long as Tranche does not implement non-constant constructor arguments.
    bytes32 internal immutable _trancheBytecodeHash;

    // Emitted when new wrapped principal token get created.
    event WrappedCoveredPrincipalTokenCreated(
        address indexed _baseToken,
        address indexed _owner
    );

    /// @notice Initializing the owner of the contract.
    constructor(address __trancheFactory, bytes32 __trancheBytecodeHash) {
        _trancheFactory = __trancheFactory;
        _trancheBytecodeHash = __trancheBytecodeHash;
    }

    /// @notice Allow the owner to create the new wrapped token.
    /// @param  _baseToken Address of the base token / underlying token that is used to buy the wrapped positions.
    /// @param  _owner Address of the owner of wrapped futures.
    /// @return address of wrapped futures token.
    function create(address _baseToken, address _owner)
        external
        returns (address)
    {
        // Validate the given params
        _zeroAddressCheck(_owner);
        _zeroAddressCheck(_baseToken);
        address wcPrincipal = address(
            new WrappedCoveredPrincipalToken(
                _baseToken,
                _owner,
                _trancheFactory,
                _trancheBytecodeHash
            )
        );
        _WrappedCoveredPrincipalTokens.add(wcPrincipal);
        emit WrappedCoveredPrincipalTokenCreated(_baseToken, _owner);
        return wcPrincipal;
    }

    /// @notice Returns the list of wrapped tokens that are whitelisted with the contract.
    ///         Order is not maintained.
    /// @return Array of addresses.
    function allWrappedCoveredPrincipalTokens()
        public
        view
        returns (address[] memory)
    {
        return _WrappedCoveredPrincipalTokens.values();
    }

    /// @notice Sanity check for the zero address check.
    function _zeroAddressCheck(address _target) internal pure {
        require(_target != address(0), "WFPF:ZERO_ADDRESS");
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.0;

import { ERC20PermitWithSupply, ERC20Permit, IERC20Permit } from "../../libraries/ERC20PermitWithSupply.sol";
import { IWrappedPosition } from "../../interfaces/IWrappedPosition.sol";
import { ITranche } from "../../interfaces/ITranche.sol";
import { IWrappedCoveredPrincipalToken } from "./interfaces/IWrappedCoveredPrincipalToken.sol";
import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

/// @author Element Finance
/// @title WrappedCoveredPrincipalToken
contract WrappedCoveredPrincipalToken is
    ERC20PermitWithSupply,
    AccessControl,
    IWrappedCoveredPrincipalToken
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    // Address of the base/underlying token which is used to buy the yield bearing token from the wrapped position.
    // Ex - Dai is used to buy the yvDai yield bearing token
    address public immutable override baseToken;

    // Enumerable address list, It contains the list of allowed wrapped positions that are covered by this contract
    // Criteria to choose the wrapped position are -
    // a). Wrapped position should have same underlying/base token (i.e ETH, BTC, USDC).
    // b). Should have the similar risk profiles.
    EnumerableSet.AddressSet private _allowedWrappedPositions;

    // Tranche factory address for Tranche contract address derivation
    address internal immutable _trancheFactory;
    // Tranche bytecode hash for Tranche contract address derivation.
    // This is constant as long as Tranche does not implement non-constant constructor arguments.
    bytes32 internal immutable _trancheBytecodeHash;

    // Role identifier that can use to do some operational stuff.
    bytes32 public constant ADMIN_ROLE = bytes32("ADMIN_ROLE");

    // Role identifier that allow a particular account to reap principal tokens out of the contract.
    bytes32 public constant RECLAIM_ROLE = bytes32("RECLAIM_ROLE");

    // Emitted when new wrapped position get whitelisted.
    event WrappedPositionAdded(address _wrappedPosition);

    // Emitted when the principal tokens get reclaimed.
    event Reclaimed(address _tranche, uint256 _amount);

    /// @notice Modifier to validate the wrapped position is whitelisted or not.
    modifier isValidWp(address _wrappedPosition) {
        require(!isAllowedWp(_wrappedPosition), "WFP:ALREADY_EXISTS");
        _;
    }

    ///@notice Initialize the wrapped token.
    ///@dev    Wrapped token have 18 decimals, It is independent of the baseToken decimals.
    constructor(
        address _baseToken,
        address _owner,
        address __trancheFactory,
        bytes32 __trancheBytecodeHash
    )
        ERC20Permit(
            _processName(IERC20Metadata(_baseToken).symbol()),
            _processSymbol(IERC20Metadata(_baseToken).symbol())
        )
    {
        baseToken = _baseToken;
        _trancheFactory = __trancheFactory;
        _trancheBytecodeHash = __trancheBytecodeHash;
        _setupRole(ADMIN_ROLE, _owner);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(RECLAIM_ROLE, ADMIN_ROLE);
    }

    ///@notice Allows to create the name for the wrapped token.
    function _processName(string memory _tokenSymbol)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked("Wrapped", _tokenSymbol, "Covered Principal")
            );
    }

    ///@notice Allows to create the symbol for the wrapped token.
    function _processSymbol(string memory _tokenSymbol)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked("W", _tokenSymbol));
    }

    /// @notice Add wrapped position within the allowed wrapped position enumerable set.
    /// @dev    It is only allowed to execute by the owner of the contract.
    ///         wrapped position which has underlying token equals to the base token are
    ///         only allowed to add, Otherwise it will revert.
    /// @param  _wrappedPosition Address of the Wrapped position which needs to add.
    function addWrappedPosition(address _wrappedPosition)
        external
        override
        isValidWp(_wrappedPosition)
        onlyRole(ADMIN_ROLE)
    {
        require(
            address(IWrappedPosition(_wrappedPosition).token()) == baseToken,
            "WFP:INVALID_WP"
        );
        _allowedWrappedPositions.add(_wrappedPosition);
        emit WrappedPositionAdded(_wrappedPosition);
    }

    /// @notice Allows the defaulter to mint wrapped tokens (Covered position) by
    ///         sending the de-pegged token to the contract.
    /// @dev    a) Only allow minting the covered position when the derived tranche got expired otherwise revert.
    ///         b) Sufficient allowance of the principal token (i.e tranche) should be provided
    ///            to the contract by the `msg.sender` to make execution successful.
    /// @param  _amount Amount of covered position / wrapped token `msg.sender` wants to mint.
    /// @param  _expiration Timestamp at which the derived tranche would get expired.
    /// @param  _wrappedPosition Address of the Wrapped position which is used to derive the tranche.
    function mint(
        uint256 _amount,
        uint256 _expiration,
        address _wrappedPosition,
        PermitData calldata _permitCallData
    ) external override {
        require(isAllowedWp(_wrappedPosition), "WFP:INVALID_WP");
        address _tranche = address(
            _deriveTranche(_wrappedPosition, _expiration)
        );
        _usePermitData(_tranche, _permitCallData);
        // Only allow minting when the position get expired.
        require(_expiration < block.timestamp, "WFP:POSITION_NOT_EXPIRED");
        // Assumed that msg.sender provides the sufficient approval the contract.
        IERC20(_tranche).safeTransferFrom(
            msg.sender,
            address(this),
            _fromWad(_amount, _tranche)
        );
        // Mint the corresponding wrapped token to the `msg.sender`.
        _mint(msg.sender, _amount);
    }

    /// @notice Tell whether the given `_wrappedPosition` is whitelisted or not.
    /// @param  _wrappedPosition Address of the wrapped position.
    /// @return returns boolean, True -> allowed otherwise false.
    function isAllowedWp(address _wrappedPosition)
        public
        view
        override
        returns (bool)
    {
        return _allowedWrappedPositions.contains(_wrappedPosition);
    }

    /// @notice Returns the list of wrapped positions that are whitelisted with the contract.
    ///         Order is not maintained.
    /// @return Array of addresses.
    function allWrappedPositions()
        external
        view
        override
        returns (address[] memory)
    {
        return _allowedWrappedPositions.values();
    }

    /// @notice Reclaim tranche token (i.e principal token) by the authorized account.
    /// @dev    Only be called by the address which has the `RECLAIM_ROLE`, Should be Nexus Treasury.
    /// @param  _expiration Timestamp at which the derived tranche would get expired.
    /// @param  _wrappedPosition Address of the Wrapped position which is used to derive the tranche.
    /// @param  _to Address whom funds gets transferred.
    function reclaimPt(
        uint256 _expiration,
        address _wrappedPosition,
        address _to
    ) external override onlyRole(RECLAIM_ROLE) {
        require(isAllowedWp(_wrappedPosition), "WFP:INVALID_WP");
        address _tranche = address(
            _deriveTranche(_wrappedPosition, _expiration)
        );
        uint256 amount = IERC20(_tranche).balanceOf(address(this));
        IERC20(_tranche).safeTransfer(_to, amount);
        emit Reclaimed(_tranche, amount);
    }

    function _usePermitData(address _tranche, PermitData memory _d) internal {
        if (_d.spender != address(0)) {
            IERC20Permit(_tranche).permit(
                msg.sender,
                _d.spender,
                _d.value,
                _d.deadline,
                _d.v,
                _d.r,
                _d.s
            );
        }
    }

    /// @notice Converts the decimal precision of given `_amount` to `_tranche` decimal.
    function _fromWad(uint256 _amount, address _tranche)
        internal
        view
        returns (uint256)
    {
        return (_amount * 10**IERC20Metadata(_tranche).decimals()) / 1e18;
    }

    /// @dev This internal function produces the deterministic create2
    ///      address of the Tranche contract from a wrapped position contract and expiration
    /// @param _position The wrapped position contract address
    /// @param _expiration The expiration time of the tranche
    /// @return The derived Tranche contract
    function _deriveTranche(address _position, uint256 _expiration)
        internal
        view
        returns (ITranche)
    {
        bytes32 salt = keccak256(abi.encodePacked(_position, _expiration));
        bytes32 addressBytes = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                _trancheFactory,
                salt,
                _trancheBytecodeHash
            )
        );
        return ITranche(address(uint160(uint256(addressBytes))));
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "./ERC20Permit.sol";

// This contract adds a total supply variable to the ERC20 lib to increase compatibility with standard
abstract contract ERC20PermitWithSupply is ERC20Permit {
    // The stored totalSupply, it equals all tokens minted - all tokens burned
    uint256 public totalSupply;

    /// @notice This function overrides the ERC20Permit Library's _mint and causes it
    ///          to track total supply.
    /// @param account the account to add tokens to
    /// @param amount the amount of tokens to add
    function _mint(address account, uint256 amount) internal override {
        // Increase account balance
        balanceOf[account] = balanceOf[account] + amount;
        // Increase total supply
        totalSupply += amount;
        // Emit a transfer from zero to emulate a mint
        emit Transfer(address(0), account, amount);
    }

    /// @notice This function overrides the ERC20Permit Library's _burn to decrement total supply
    /// @param account the account to burn from
    /// @param amount the amount of token to burn
    function _burn(address account, uint256 amount) internal override {
        // Decrease user balance
        balanceOf[account] = balanceOf[account] - amount;
        // Decrease total supply
        totalSupply -= amount;
        // Emit an event tracking the burn
        emit Transfer(account, address(0), amount);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IERC20Permit.sol";
import "./IERC20.sol";

interface IWrappedPosition is IERC20Permit {
    function token() external view returns (IERC20);

    function balanceOfUnderlying(address who) external view returns (uint256);

    function getSharesToUnderlying(uint256 shares)
        external
        view
        returns (uint256);

    function deposit(address sender, uint256 amount) external returns (uint256);

    function withdraw(
        address sender,
        uint256 _shares,
        uint256 _minUnderlying
    ) external returns (uint256);

    function withdrawUnderlying(
        address _destination,
        uint256 _amount,
        uint256 _minUnderlying
    ) external returns (uint256, uint256);

    function prefundedDeposit(address _destination)
        external
        returns (
            uint256,
            uint256,
            uint256
        );
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IERC20Permit.sol";
import "./IInterestToken.sol";

interface ITranche is IERC20Permit {
    function deposit(uint256 _shares, address destination)
        external
        returns (uint256, uint256);

    function prefundedDeposit(address _destination)
        external
        returns (uint256, uint256);

    function withdrawPrincipal(uint256 _amount, address _destination)
        external
        returns (uint256);

    function withdrawInterest(uint256 _amount, address _destination)
        external
        returns (uint256);

    function interestToken() external view returns (IInterestToken);

    function interestSupply() external view returns (uint128);

    function underlying() external view returns (IERC20);

    function unlockTimestamp() external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.0;

import { IERC20Permit } from "../../../interfaces/IERC20Permit.sol";

interface IWrappedCoveredPrincipalToken is IERC20Permit {
    // Memory encoding of the permit data
    struct PermitData {
        address spender;
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    // Address of the base/underlying token which is used to buy the yield bearing token from the wrapped position.
    // Ex - Dai is used to buy the yvDai yield bearing token.
    function baseToken() external view returns (address);

    /// @notice Add wrapped position within the allowed wrapped position enumerable set.
    /// @dev    It is only allowed to execute by the owner of the contract.
    ///         wrapped position which has underlying token equals to the base token are
    ///         only allowed to add, Otherwise it will revert.
    /// @param  _wrappedPosition Address of the Wrapped position which needs to add.
    function addWrappedPosition(address _wrappedPosition) external;

    /// @notice Allows the defaulter to mint wrapped tokens (Covered position) by
    ///         sending the de-pegged token to the contract.
    /// @dev    a) Only allow minting the covered position when the derived tranche got expired otherwise revert.
    ///         b) Sufficient allowance of the principal token (i.e tranche) should be provided
    ///            to the contract by the `msg.sender` to make execution successful.
    /// @param  _amount Amount of covered position / wrapped token `msg.sender` wants to mint.
    /// @param  _expiration Timestamp at which the derived tranche would get expired.
    /// @param  _wrappedPosition Address of the Wrapped position which is used to derive the tranche.
    function mint(
        uint256 _amount,
        uint256 _expiration,
        address _wrappedPosition,
        PermitData calldata _permitCallData
    ) external;

    /// @notice Tell whether the given `_wrappedPosition` is whitelisted or not.
    /// @param  _wrappedPosition Address of the wrapped position.
    /// @return returns boolean, True -> allowed otherwise false.
    function isAllowedWp(address _wrappedPosition) external view returns (bool);

    /// @notice Returns the list of wrapped positions that are whitelisted with the contract.
    ///         Order is not maintained.
    /// @return Array of addresses.
    function allWrappedPositions() external view returns (address[] memory);

    /// @notice Reclaim tranche token (i.e principal token) by the authorized account.
    /// @dev    Only be called by the address which has the `RECLAIM_ROLE`, Should be Nexus Treasury.
    /// @param  _expiration Timestamp at which the derived tranche would get expired.
    /// @param  _wrappedPosition Address of the Wrapped position which is used to derive the tranche.
    /// @param  _to Address whom funds gets transferred.
    function reclaimPt(
        uint256 _expiration,
        address _wrappedPosition,
        address _to
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

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
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
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
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
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

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "../interfaces/IERC20Permit.sol";

// This default erc20 library is designed for max efficiency and security.
// WARNING: By default it does not include totalSupply which breaks the ERC20 standard
//          to use a fully standard compliant ERC20 use 'ERC20PermitWithSupply"
abstract contract ERC20Permit is IERC20Permit {
    // --- ERC20 Data ---
    // The name of the erc20 token
    string public name;
    // The symbol of the erc20 token
    string public override symbol;
    // The decimals of the erc20 token, should default to 18 for new tokens
    uint8 public override decimals;

    // A mapping which tracks user token balances
    mapping(address => uint256) public override balanceOf;
    // A mapping which tracks which addresses a user allows to move their tokens
    mapping(address => mapping(address => uint256)) public override allowance;
    // A mapping which tracks the permit signature nonces for users
    mapping(address => uint256) public override nonces;

    // --- EIP712 niceties ---
    // solhint-disable-next-line var-name-mixedcase
    bytes32 public override DOMAIN_SEPARATOR;
    // bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /// @notice Initializes the erc20 contract
    /// @param name_ the value 'name' will be set to
    /// @param symbol_ the value 'symbol' will be set to
    /// @dev decimals default to 18 and must be reset by an inheriting contract for
    ///      non standard decimal values
    constructor(string memory name_, string memory symbol_) {
        // Set the state variables
        name = name_;
        symbol = symbol_;
        decimals = 18;

        // By setting these addresses to 0 attempting to execute a transfer to
        // either of them will revert. This is a gas efficient way to prevent
        // a common user mistake where they transfer to the token address.
        // These values are not considered 'real' tokens and so are not included
        // in 'total supply' which only contains minted tokens.
        balanceOf[address(0)] = type(uint256).max;
        balanceOf[address(this)] = type(uint256).max;

        // Optional extra state manipulation
        _extraConstruction();

        // Computes the EIP 712 domain separator which prevents user signed messages for
        // this contract to be replayed in other contracts.
        // https://eips.ethereum.org/EIPS/eip-712
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    /// @notice An optional override function to execute and change state before immutable assignment
    function _extraConstruction() internal virtual {}

    // --- Token ---
    /// @notice Allows a token owner to send tokens to another address
    /// @param recipient The address which will be credited with the tokens
    /// @param amount The amount user token to send
    /// @return returns true on success, reverts on failure so cannot return false.
    /// @dev transfers to this contract address or 0 will fail
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        // We forward this call to 'transferFrom'
        return transferFrom(msg.sender, recipient, amount);
    }

    /// @notice Transfers an amount of erc20 from a spender to a receipt
    /// @param spender The source of the ERC20 tokens
    /// @param recipient The destination of the ERC20 tokens
    /// @param amount the number of tokens to send
    /// @return returns true on success and reverts on failure
    /// @dev will fail transfers which send funds to this contract or 0
    function transferFrom(
        address spender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        // Load balance and allowance
        uint256 balance = balanceOf[spender];
        require(balance >= amount, "ERC20: insufficient-balance");
        // We potentially have to change allowances
        if (spender != msg.sender) {
            // Loading the allowance in the if block prevents vanilla transfers
            // from paying for the sload.
            uint256 allowed = allowance[spender][msg.sender];
            // If the allowance is max we do not reduce it
            // Note - This means that max allowances will be more gas efficient
            // by not requiring a sstore on 'transferFrom'
            if (allowed != type(uint256).max) {
                require(allowed >= amount, "ERC20: insufficient-allowance");
                allowance[spender][msg.sender] = allowed - amount;
            }
        }
        // Update the balances
        balanceOf[spender] = balance - amount;
        // Note - In the constructor we initialize the 'balanceOf' of address 0 and
        //        the token address to uint256.max and so in 8.0 transfers to those
        //        addresses revert on this step.
        balanceOf[recipient] = balanceOf[recipient] + amount;
        // Emit the needed event
        emit Transfer(spender, recipient, amount);
        // Return that this call succeeded
        return true;
    }

    /// @notice This internal minting function allows inheriting contracts
    ///         to mint tokens in the way they wish.
    /// @param account the address which will receive the token.
    /// @param amount the amount of token which they will receive
    /// @dev This function is virtual so that it can be overridden, if you
    ///      are reviewing this contract for security you should ensure to
    ///      check for overrides
    function _mint(address account, uint256 amount) internal virtual {
        // Add tokens to the account
        balanceOf[account] = balanceOf[account] + amount;
        // Emit an event to track the minting
        emit Transfer(address(0), account, amount);
    }

    /// @notice This internal burning function allows inheriting contracts to
    ///         burn tokens in the way they see fit.
    /// @param account the account to remove tokens from
    /// @param amount  the amount of tokens to remove
    /// @dev This function is virtual so that it can be overridden, if you
    ///      are reviewing this contract for security you should ensure to
    ///      check for overrides
    function _burn(address account, uint256 amount) internal virtual {
        // Reduce the balance of the account
        balanceOf[account] = balanceOf[account] - amount;
        // Emit an event tracking transfers
        emit Transfer(account, address(0), amount);
    }

    /// @notice This function allows a user to approve an account which can transfer
    ///         tokens on their behalf.
    /// @param account The account which will be approve to transfer tokens
    /// @param amount The approval amount, if set to uint256.max the allowance does not go down on transfers.
    /// @return returns true for compatibility with the ERC20 standard
    function approve(address account, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        // Set the senders allowance for account to amount
        allowance[msg.sender][account] = amount;
        // Emit an event to track approvals
        emit Approval(msg.sender, account, amount);
        return true;
    }

    /// @notice This function allows a caller who is not the owner of an account to execute the functionality of 'approve' with the owners signature.
    /// @param owner the owner of the account which is having the new approval set
    /// @param spender the address which will be allowed to spend owner's tokens
    /// @param value the new allowance value
    /// @param deadline the timestamp which the signature must be submitted by to be valid
    /// @param v Extra ECDSA data which allows public key recovery from signature assumed to be 27 or 28
    /// @param r The r component of the ECDSA signature
    /// @param s The s component of the ECDSA signature
    /// @dev The signature for this function follows EIP 712 standard and should be generated with the
    ///      eth_signTypedData JSON RPC call instead of the eth_sign JSON RPC call. If using out of date
    ///      parity signing libraries the v component may need to be adjusted. Also it is very rare but possible
    ///      for v to be other values, those values are not supported.
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        // The EIP 712 digest for this function
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        nonces[owner],
                        deadline
                    )
                )
            )
        );
        // Require that the owner is not zero
        require(owner != address(0), "ERC20: invalid-address-0");
        // Require that we have a valid signature from the owner
        require(owner == ecrecover(digest, v, r, s), "ERC20: invalid-permit");
        // Require that the signature is not expired
        require(
            deadline == 0 || block.timestamp <= deadline,
            "ERC20: permit-expired"
        );
        // Format the signature to the default format
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ERC20: invalid signature 's' value"
        );
        // Increment the signature nonce to prevent replay
        nonces[owner]++;
        // Set the allowance to the new value
        allowance[owner][spender] = value;
        // Emit an approval event to be able to track this happening
        emit Approval(owner, spender, value);
    }

    /// @notice Internal function which allows inheriting contract to set custom decimals
    /// @param decimals_ the new decimal value
    function _setupDecimals(uint8 decimals_) internal {
        // Set the decimals
        decimals = decimals_;
    }
}

// Forked from openzepplin
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit is IERC20 {
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for `permit`, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IERC20 {
    function symbol() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    // Note this is non standard but nearly all ERC20 have exposed decimal functions
    function decimals() external view returns (uint8);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IERC20Permit.sol";

interface IInterestToken is IERC20Permit {
    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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