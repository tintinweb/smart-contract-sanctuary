/**
 *Submitted for verification at Etherscan.io on 2021-02-12
*/

// File: @openzeppelin/contracts/proxy/Proxy.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

// File: @openzeppelin/contracts/utils/Address.sol



pragma solidity >=0.6.2 <0.8.0;

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

// File: @openzeppelin/contracts/proxy/UpgradeableProxy.sol



pragma solidity >=0.6.0 <0.8.0;



/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 *
 * Upgradeability is only provided internally through {_upgradeTo}. For an externally upgradeable proxy see
 * {TransparentUpgradeableProxy}.
 */
contract UpgradeableProxy is Proxy {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) public payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _setImplementation(_logic);
        if(_data.length > 0) {
            Address.functionDelegateCall(_logic, _data);
        }
    }

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Upgrades the proxy to a new implementation.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal virtual {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableProxy: new implementation is not a contract");

        bytes32 slot = _IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementation)
        }
    }
}

// File: contracts/UpgradeableExtension.sol



pragma solidity >=0.6.0 <0.8.0;



/**
 * @dev This contract implements an upgradeable extension. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 *
 * Upgradeability is only provided internally through {_upgradeTo}. For an externally upgradeable proxy see
 * {TransparentUpgradeableProxy}.
 */
contract UpgradeableExtension is Proxy {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor() public payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
    }

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Upgrades the proxy to a new implementation.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal virtual {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(
            newImplementation == address(0x0) || Address.isContract(newImplementation),
            "UpgradeableExtension: new implementation must be 0x0 or a contract"
        );

        bytes32 slot = _IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementation)
        }
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.6.0;

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

// File: openzeppelin-solidity/contracts/math/SafeMath.sol



pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: openzeppelin-solidity/contracts/utils/Address.sol



pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address62 {
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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol



pragma solidity ^0.6.0;




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
    using SafeMath for uint256;
    using Address62 for address;

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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

// File: openzeppelin-solidity/contracts/GSN/Context.sol



pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol



pragma solidity ^0.6.0;





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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address62 for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// File: openzeppelin-solidity/contracts/access/Ownable.sol



pragma solidity ^0.6.0;

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

// File: openzeppelin-solidity/contracts/math/Math.sol



pragma solidity ^0.6.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// File: contracts/ReentrancyGuardPausable.sol



pragma solidity ^0.6.0;


/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Reuse openzeppelin's ReentrancyGuard with Pausable feature
 */
contract ReentrancyGuardPausable {
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
    uint256 private constant _PAUSEDV1 = 4;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrantAndUnpaused(uint256 version) {
        {
        uint256 status = _status;

        // On the first call to nonReentrant, _notEntered will be true
        require((status & (1 << (version + 1))) == 0, "ReentrancyGuard: paused");
        require((status & _ENTERED) == 0, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = status ^ _ENTERED;
        }

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status ^= _ENTERED;
    }

    modifier nonReentrantAndUnpausedV1() {
        {
        uint256 status = _status;

        // On the first call to nonReentrant, _notEntered will be true
        require((status & _PAUSEDV1) == 0, "ReentrancyGuard: paused");
        require((status & _ENTERED) == 0, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = status ^ _ENTERED;
        }

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status ^= _ENTERED;
    }

    function _pause(uint256 flag) internal {
        _status |= flag;
    }

    function _unpause(uint256 flag) internal {
        _status &= ~flag;
    }
}

// File: contracts/YERC20.sol


pragma solidity ^0.6.0;



/* TODO: Actually methods are public instead of external */
interface YERC20 is IERC20 {
    function getPricePerFullShare() external view returns (uint256);

    function deposit(uint256 _amount) external;

    function withdraw(uint256 _shares) external;
}

// File: contracts/SmoothyV1.sol


pragma solidity ^0.6.0;










contract SmoothyV1 is ReentrancyGuardPausable, ERC20, Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 constant W_ONE = 1e18;
    uint256 constant U256_1 = 1;
    uint256 constant SWAP_FEE_MAX = 2e17;
    uint256 constant REDEEM_FEE_MAX = 2e17;
    uint256 constant ADMIN_FEE_PCT_MAX = 5e17;

    /** @dev Fee collector of the contract */
    address public _rewardCollector;

    // Using mapping instead of array to save gas
    mapping(uint256 => uint256) public _tokenInfos;
    mapping(uint256 => address) public _yTokenAddresses;

    // Best estimate of token balance in y pool.
    // Save the gas cost of calling yToken to evaluate balanceInToken.
    mapping(uint256 => uint256) public _yBalances;

    /*
     * _totalBalance is expected to >= sum(_getBalance()'s), where the diff is the admin fee
     * collected by _collectReward().
     */
    uint256 public _totalBalance;
    uint256 public _swapFee = 4e14; // 1E18 means 100%
    uint256 public _redeemFee = 0; // 1E18 means 100%
    uint256 public _adminFeePct = 0; // % of swap/redeem fee to admin
    uint256 public _adminInterestPct = 0; // % of interest to admins

    uint256 public _ntokens;

    uint256 constant YENABLE_OFF = 40;
    uint256 constant DECM_OFF = 41;
    uint256 constant TID_OFF = 46;

    event Swap(
        address indexed buyer,
        uint256 bTokenIdIn,
        uint256 bTokenIdOut,
        uint256 inAmount,
        uint256 outAmount
    );

    event SwapAll(
        address indexed provider,
        uint256[] amounts,
        uint256 inOutFlag,
        uint256 sTokenMintedOrBurned
    );

    event Mint(
        address indexed provider,
        uint256 inAmounts,
        uint256 sTokenMinted
    );

    event Redeem(
        address indexed provider,
        uint256 bTokenAmount,
        uint256 sTokenBurn
    );

    constructor (
        address[] memory tokens,
        address[] memory yTokens,
        uint256[] memory decMultipliers,
        uint256[] memory softWeights,
        uint256[] memory hardWeights
    )
        public
        ERC20("Smoothy LP Token", "syUSD")
    {
        require(tokens.length == yTokens.length, "tokens and ytokens must have the same length");
        require(
            tokens.length == decMultipliers.length,
            "tokens and decMultipliers must have the same length"
        );
        require(
            tokens.length == hardWeights.length,
            "incorrect hard wt. len"
        );
        require(
            tokens.length == softWeights.length,
            "incorrect soft wt. len"
        );
        _rewardCollector = msg.sender;

        for (uint8 i = 0; i < tokens.length; i++) {
            uint256 info = uint256(tokens[i]);
            require(hardWeights[i] >= softWeights[i], "hard wt. must >= soft wt.");
            require(hardWeights[i] <= W_ONE, "hard wt. must <= 1e18");
            info = _setHardWeight(info, hardWeights[i]);
            info = _setSoftWeight(info, softWeights[i]);
            info = _setDecimalMultiplier(info, decMultipliers[i]);
            info = _setTID(info, i);
            _yTokenAddresses[i] = yTokens[i];
            // _balances[i] = 0; // no need to set
            if (yTokens[i] != address(0x0)) {
                info = _setYEnabled(info, true);
            }
            _tokenInfos[i] = info;
        }
        _ntokens = tokens.length;
    }

    /***************************************
     * Methods to change a token info
     ***************************************/

    /* return soft weight in 1e18 */
    function _getSoftWeight(uint256 info) internal pure returns (uint256 w) {
        return ((info >> 160) & ((U256_1 << 20) - 1)) * 1e12;
    }

    function _setSoftWeight(
        uint256 info,
        uint256 w
    )
        internal
        pure
        returns (uint256 newInfo)
    {
        require (w <= W_ONE, "soft weight must <= 1e18");

        // Only maintain 1e6 resolution.
        newInfo = info & ~(((U256_1 << 20) - 1) << 160);
        newInfo = newInfo | ((w / 1e12) << 160);
    }

    function _getHardWeight(uint256 info) internal pure returns (uint256 w) {
        return ((info >> 180) & ((U256_1 << 20) - 1)) * 1e12;
    }

    function _setHardWeight(
        uint256 info,
        uint256 w
    )
        internal
        pure
        returns (uint256 newInfo)
    {
        require (w <= W_ONE, "hard weight must <= 1e18");

        // Only maintain 1e6 resolution.
        newInfo = info & ~(((U256_1 << 20) - 1) << 180);
        newInfo = newInfo | ((w / 1e12) << 180);
    }

    function _getDecimalMulitiplier(uint256 info) internal pure returns (uint256 dec) {
        return (info >> (160 + DECM_OFF)) & ((U256_1 << 5) - 1);
    }

    function _setDecimalMultiplier(
        uint256 info,
        uint256 decm
    )
        internal
        pure
        returns (uint256 newInfo)
    {
        require (decm < 18, "decimal multipler is too large");
        newInfo = info & ~(((U256_1 << 5) - 1) << (160 + DECM_OFF));
        newInfo = newInfo | (decm << (160 + DECM_OFF));
    }

    function _isYEnabled(uint256 info) internal pure returns (bool) {
        return (info >> (160 + YENABLE_OFF)) & 0x1 == 0x1;
    }

    function _setYEnabled(uint256 info, bool enabled) internal pure returns (uint256) {
        if (enabled) {
            return info | (U256_1 << (160 + YENABLE_OFF));
        } else {
            return info & ~(U256_1 << (160 + YENABLE_OFF));
        }
    }

    function _setTID(uint256 info, uint256 tid) internal pure returns (uint256) {
        require (tid < 256, "tid is too large");
        require (_getTID(info) == 0, "tid cannot set again");
        return info | (tid << (160 + TID_OFF));
    }

    function _getTID(uint256 info) internal pure returns (uint256) {
        return (info >> (160 + TID_OFF)) & 0xFF;
    }

    /****************************************
     * Owner methods
     ****************************************/
    function pause(uint256 flag) external onlyOwner {
        _pause(flag);
    }

    function unpause(uint256 flag) external onlyOwner {
        _unpause(flag);
    }

    function changeRewardCollector(address newCollector) external onlyOwner {
        _rewardCollector = newCollector;
    }

    function adjustWeights(
        uint8 tid,
        uint256 newSoftWeight,
        uint256 newHardWeight
    )
        external
        onlyOwner
    {
        require(newSoftWeight <= newHardWeight, "Soft-limit weight must <= Hard-limit weight");
        require(newHardWeight <= W_ONE, "hard-limit weight must <= 1");
        require(tid < _ntokens, "Backed token not exists");

        _tokenInfos[tid] = _setSoftWeight(_tokenInfos[tid], newSoftWeight);
        _tokenInfos[tid] = _setHardWeight(_tokenInfos[tid], newHardWeight);
    }

    function changeSwapFee(uint256 swapFee) external onlyOwner {
        require(swapFee <= SWAP_FEE_MAX, "Swap fee must is too large");
        _swapFee = swapFee;
    }

    function changeRedeemFee(
        uint256 redeemFee
    )
        external
        onlyOwner
    {
        require(redeemFee <= REDEEM_FEE_MAX, "Redeem fee is too large");
        _redeemFee = redeemFee;
    }

    function changeAdminFeePct(uint256 pct) external onlyOwner {
        require (pct <= ADMIN_FEE_PCT_MAX, "Admin fee pct is too large");
        _adminFeePct = pct;
    }

    function changeAdminInterestPct(uint256 pct) external onlyOwner {
        require (pct <= ADMIN_FEE_PCT_MAX, "Admin interest fee pct is too large");
        _adminInterestPct = pct;
    }

    function initialize(
        uint8 tid,
        uint256 bTokenAmount
    )
        external
        onlyOwner
    {
        require(tid < _ntokens, "Backed token not exists");
        uint256 info = _tokenInfos[tid];
        address addr = address(info);

        IERC20(addr).safeTransferFrom(
            msg.sender,
            address(this),
            bTokenAmount
        );
        _totalBalance = _totalBalance.add(bTokenAmount.mul(_normalizeBalance(info)));
        _mint(msg.sender, bTokenAmount.mul(_normalizeBalance(info)));
    }

    function addToken(
        address addr,
        address yAddr,
        uint256 softWeight,
        uint256 hardWeight,
        uint256 decMultiplier
    )
        external
        onlyOwner
    {
        uint256 tid = _ntokens;
        for (uint256 i = 0; i < tid; i++) {
            require(address(_tokenInfos[i]) != addr, "cannot add dup token");
        }

        require (softWeight <= hardWeight, "soft weight must <= hard weight");

        uint256 info = uint256(addr);
        info = _setTID(info, tid);
        info = _setYEnabled(info, yAddr != address(0x0));
        info = _setSoftWeight(info, softWeight);
        info = _setHardWeight(info, hardWeight);
        info = _setDecimalMultiplier(info, decMultiplier);

        _tokenInfos[tid] = info;
        _yTokenAddresses[tid] = yAddr;
        // _balances[tid] = 0; // no need to set
        _ntokens = tid.add(1);
    }

    function setYEnabled(uint256 tid, address yAddr) external onlyOwner {
        uint256 info = _tokenInfos[tid];
        if (_yTokenAddresses[tid] != address(0x0)) {
            // Withdraw all tokens from yToken, and clear yBalance.
            uint256 pricePerShare = YERC20(_yTokenAddresses[tid]).getPricePerFullShare();
            uint256 share = YERC20(_yTokenAddresses[tid]).balanceOf(address(this));
            uint256 cash = _getCashBalance(info);
            YERC20(_yTokenAddresses[tid]).withdraw(share);
            uint256 dcash = _getCashBalance(info).sub(cash);
            require(dcash >= pricePerShare.mul(share).div(W_ONE), "ytoken withdraw amount < expected");

            // Update _totalBalance with interest
            _updateTotalBalanceWithNewYBalance(tid, dcash);
            _yBalances[tid] = 0;
        }

        info = _setYEnabled(info, yAddr != address(0x0));
        _yTokenAddresses[tid] = yAddr;
        _tokenInfos[tid] = info;
        // If yAddr != 0x0, we will rebalance in next swap/mint/redeem/rebalance call.
    }

    /**
     * Calculate binary logarithm of x.  Revert if x <= 0.
     * See LICENSE_LOG.md for license.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function lg2(int128 x) internal pure returns (int128) {
        require (x > 0, "x must be positive");

        int256 msb = 0;
        int256 xc = x;

        if (xc >= 0x10000000000000000) {xc >>= 64; msb += 64;}
        if (xc >= 0x100000000) {xc >>= 32; msb += 32;}
        if (xc >= 0x10000) {xc >>= 16; msb += 16;}
        if (xc >= 0x100) {xc >>= 8; msb += 8;}
        if (xc >= 0x10) {xc >>= 4; msb += 4;}
        if (xc >= 0x4) {xc >>= 2; msb += 2;}
        if (xc >= 0x2) {msb += 1;}  // No need to shift xc anymore

        int256 result = (msb - 64) << 64;
        uint256 ux = uint256 (x) << (127 - msb);
        /* 20 iterations so that the resolution is aboout 2^-20 \approx 5e-6 */
        for (int256 bit = 0x8000000000000000; bit > 0x80000000000; bit >>= 1) {
            ux *= ux;
            uint256 b = ux >> 255;
            ux >>= 127 + b;
            result += bit * int256(b);
        }

        return int128(result);
    }

    function _safeToInt128(uint256 x) internal pure returns (int128 y) {
        y = int128(x);
        require(x == uint256(y), "Conversion to int128 failed");
        return y;
    }

    /**
     * @dev Return the approx logarithm of a value with log(x) where x <= 1.1.
     * All values are in integers with (1e18 == 1.0).
     *
     * Requirements:
     *
     * - input value x must be greater than 1e18
     */
    function _logApprox(uint256 x) internal pure returns (uint256 y) {
        uint256 one = W_ONE;

        require(x >= one, "logApprox: x must >= 1");

        uint256 z = x - one;
        uint256 zz = z.mul(z).div(one);
        uint256 zzz = zz.mul(z).div(one);
        uint256 zzzz = zzz.mul(z).div(one);
        uint256 zzzzz = zzzz.mul(z).div(one);
        return z.sub(zz.div(2)).add(zzz.div(3)).sub(zzzz.div(4)).add(zzzzz.div(5));
    }

    /**
     * @dev Return the logarithm of a value.
     * All values are in integers with (1e18 == 1.0).
     *
     * Requirements:
     *
     * - input value x must be greater than 1e18
     */
    function _log(uint256 x) internal pure returns (uint256 y) {
        require(x >= W_ONE, "log(x): x must be greater than 1");
        require(x < (W_ONE << 63), "log(x): x is too large");

        if (x <= W_ONE.add(W_ONE.div(10))) {
            return _logApprox(x);
        }

        /* Convert to 64.64 float point */
        int128 xx = _safeToInt128((x << 64) / W_ONE);

        int128 yy = lg2(xx);

        /* log(2) * 1e18 \approx 693147180559945344 */
        y = (uint256(yy) * 693147180559945344) >> 64;

        return y;
    }

    /**
     * Return weights and cached balances of all tokens
     * Note that the cached balance does not include the accrued interest since last rebalance.
     */
    function _getBalancesAndWeights()
        internal
        view
        returns (uint256[] memory balances, uint256[] memory softWeights, uint256[] memory hardWeights, uint256 totalBalance)
    {
        uint256 ntokens = _ntokens;
        balances = new uint256[](ntokens);
        softWeights = new uint256[](ntokens);
        hardWeights = new uint256[](ntokens);
        totalBalance = 0;
        for (uint8 i = 0; i < ntokens; i++) {
            uint256 info = _tokenInfos[i];
            balances[i] = _getCashBalance(info);
            if (_isYEnabled(info)) {
                balances[i] = balances[i].add(_yBalances[i]);
            }
            totalBalance = totalBalance.add(balances[i]);
            softWeights[i] = _getSoftWeight(info);
            hardWeights[i] = _getHardWeight(info);
        }
    }

    function _getBalancesAndInfos()
        internal
        view
        returns (uint256[] memory balances, uint256[] memory infos, uint256 totalBalance)
    {
        uint256 ntokens = _ntokens;
        balances = new uint256[](ntokens);
        infos = new uint256[](ntokens);
        totalBalance = 0;
        for (uint8 i = 0; i < ntokens; i++) {
            infos[i] = _tokenInfos[i];
            balances[i] = _getCashBalance(infos[i]);
            if (_isYEnabled(infos[i])) {
                balances[i] = balances[i].add(_yBalances[i]);
            }
            totalBalance = totalBalance.add(balances[i]);
        }
    }

    function _getBalance(uint256 info) internal view returns (uint256 balance) {
        balance = _getCashBalance(info);
        if (_isYEnabled(info)) {
            balance = balance.add(_yBalances[_getTID(info)]);
        }
    }

    function getBalance(uint256 tid) public view returns (uint256) {
        return _getBalance(_tokenInfos[tid]);
    }

    function _normalizeBalance(uint256 info) internal pure returns (uint256) {
        uint256 decm = _getDecimalMulitiplier(info);
        return 10 ** decm;
    }

    /* @dev Return normalized cash balance of a token */
    function _getCashBalance(uint256 info) internal view returns (uint256) {
        return IERC20(address(info)).balanceOf(address(this))
            .mul(_normalizeBalance(info));
    }

    function _getBalanceDetail(
        uint256 info
    )
        internal
        view
        returns (uint256 pricePerShare, uint256 cashUnnormalized, uint256 yBalanceUnnormalized)
    {
        address yAddr = _yTokenAddresses[_getTID(info)];
        pricePerShare = YERC20(yAddr).getPricePerFullShare();
        cashUnnormalized = IERC20(address(info)).balanceOf(address(this));
        uint256 share = YERC20(yAddr).balanceOf(address(this));
        yBalanceUnnormalized = share.mul(pricePerShare).div(W_ONE);
    }

    /**************************************************************************************
     * Methods for rebalance cash reserve
     * After rebalancing, we will have cash reserve equaling to 10% of total balance
     * There are two conditions to trigger a rebalancing
     * - if there is insufficient cash for withdraw; or
     * - if the cash reserve is greater than 20% of total balance.
     * Note that we use a cached version of total balance to avoid high gas cost on calling
     * getPricePerFullShare().
     *************************************************************************************/
    function _updateTotalBalanceWithNewYBalance(
        uint256 tid,
        uint256 yBalanceNormalizedNew
    )
        internal
    {
        uint256 adminFee = 0;
        uint256 yBalanceNormalizedOld = _yBalances[tid];
        // They yBalance should not be decreasing, but just in case,
        if (yBalanceNormalizedNew >= yBalanceNormalizedOld) {
            adminFee = (yBalanceNormalizedNew - yBalanceNormalizedOld).mul(_adminInterestPct).div(W_ONE);
        }
        _totalBalance = _totalBalance
            .sub(yBalanceNormalizedOld)
            .add(yBalanceNormalizedNew)
            .sub(adminFee);
    }

    function _rebalanceReserve(
        uint256 info
    )
        internal
    {
        require(_isYEnabled(info), "yToken must be enabled for rebalancing");

        uint256 pricePerShare;
        uint256 cashUnnormalized;
        uint256 yBalanceUnnormalized;
        (pricePerShare, cashUnnormalized, yBalanceUnnormalized) = _getBalanceDetail(info);
        uint256 tid = _getTID(info);

        // Update _totalBalance with interest
        _updateTotalBalanceWithNewYBalance(tid, yBalanceUnnormalized.mul(_normalizeBalance(info)));

        uint256 targetCash = yBalanceUnnormalized.add(cashUnnormalized).div(10);
        if (cashUnnormalized > targetCash) {
            uint256 depositAmount = cashUnnormalized.sub(targetCash);
            // Reset allowance to bypass possible allowance check (e.g., USDT)
            IERC20(address(info)).safeApprove(_yTokenAddresses[tid], 0);
            IERC20(address(info)).safeApprove(_yTokenAddresses[tid], depositAmount);

            // Calculate acutal deposit in the case that some yTokens may return partial deposit.
            uint256 balanceBefore = IERC20(address(info)).balanceOf(address(this));
            YERC20(_yTokenAddresses[tid]).deposit(depositAmount);
            uint256 actualDeposit = balanceBefore.sub(IERC20(address(info)).balanceOf(address(this)));
            _yBalances[tid] = yBalanceUnnormalized.add(actualDeposit).mul(_normalizeBalance(info));
        } else {
            uint256 expectedWithdraw = targetCash.sub(cashUnnormalized);
            if (expectedWithdraw == 0) {
                return;
            }

            uint256 balanceBefore = IERC20(address(info)).balanceOf(address(this));
            // Withdraw +1 wei share to make sure actual withdraw >= expected.
            YERC20(_yTokenAddresses[tid]).withdraw(expectedWithdraw.mul(W_ONE).div(pricePerShare).add(1));
            uint256 actualWithdraw = IERC20(address(info)).balanceOf(address(this)).sub(balanceBefore);
            require(actualWithdraw >= expectedWithdraw, "insufficient cash withdrawn from yToken");
            _yBalances[tid] = yBalanceUnnormalized.sub(actualWithdraw).mul(_normalizeBalance(info));
        }
    }

    /* @dev Forcibly rebalance so that cash reserve is about 10% of total. */
    function rebalanceReserve(
        uint256 tid
    )
        external
        nonReentrantAndUnpausedV1
    {
        _rebalanceReserve(_tokenInfos[tid]);
    }

    /*
     * @dev Rebalance the cash reserve so that
     * cash reserve consists of 10% of total balance after substracting amountUnnormalized.
     *
     * Assume that current cash reserve < amountUnnormalized.
     */
    function _rebalanceReserveSubstract(
        uint256 info,
        uint256 amountUnnormalized
    )
        internal
    {
        require(_isYEnabled(info), "yToken must be enabled for rebalancing");

        uint256 pricePerShare;
        uint256 cashUnnormalized;
        uint256 yBalanceUnnormalized;
        (pricePerShare, cashUnnormalized, yBalanceUnnormalized) = _getBalanceDetail(info);

        // Update _totalBalance with interest
        _updateTotalBalanceWithNewYBalance(
            _getTID(info),
            yBalanceUnnormalized.mul(_normalizeBalance(info))
        );

        // Evaluate the shares to withdraw so that cash = 10% of total
        uint256 expectedWithdraw = cashUnnormalized.add(yBalanceUnnormalized).sub(
            amountUnnormalized).div(10).add(amountUnnormalized).sub(cashUnnormalized);
        if (expectedWithdraw == 0) {
            return;
        }

        // Withdraw +1 wei share to make sure actual withdraw >= expected.
        uint256 withdrawShares = expectedWithdraw.mul(W_ONE).div(pricePerShare).add(1);
        uint256 balanceBefore = IERC20(address(info)).balanceOf(address(this));
        YERC20(_yTokenAddresses[_getTID(info)]).withdraw(withdrawShares);
        uint256 actualWithdraw = IERC20(address(info)).balanceOf(address(this)).sub(balanceBefore);
        require(actualWithdraw >= expectedWithdraw, "insufficient cash withdrawn from yToken");
        _yBalances[_getTID(info)] = yBalanceUnnormalized.sub(actualWithdraw)
            .mul(_normalizeBalance(info));
    }

    /* @dev Transfer the amount of token out.  Rebalance the cash reserve if needed */
    function _transferOut(
        uint256 info,
        uint256 amountUnnormalized,
        uint256 adminFee
    )
        internal
    {
        uint256 amountNormalized = amountUnnormalized.mul(_normalizeBalance(info));
        if (_isYEnabled(info)) {
            if (IERC20(address(info)).balanceOf(address(this)) < amountUnnormalized) {
                _rebalanceReserveSubstract(info, amountUnnormalized);
            }
        }

        IERC20(address(info)).safeTransfer(
            msg.sender,
            amountUnnormalized
        );
        _totalBalance = _totalBalance
            .sub(amountNormalized)
            .sub(adminFee.mul(_normalizeBalance(info)));
    }

    /* @dev Transfer the amount of token in.  Rebalance the cash reserve if needed */
    function _transferIn(
        uint256 info,
        uint256 amountUnnormalized
    )
        internal
    {
        uint256 amountNormalized = amountUnnormalized.mul(_normalizeBalance(info));
        IERC20(address(info)).safeTransferFrom(
            msg.sender,
            address(this),
            amountUnnormalized
        );
        _totalBalance = _totalBalance.add(amountNormalized);

        // If there is saving ytoken, save the balance in _balance.
        if (_isYEnabled(info)) {
            uint256 tid = _getTID(info);
            /* Check rebalance if needed */
            uint256 cash = _getCashBalance(info);
            if (cash > cash.add(_yBalances[tid]).mul(2).div(10)) {
                _rebalanceReserve(info);
            }
        }
    }

    /**************************************************************************************
     * Methods for minting LP tokens
     *************************************************************************************/

    /*
     * @dev Return the amount of sUSD should be minted after depositing bTokenAmount into the pool
     * @param bTokenAmountNormalized - normalized amount of token to be deposited
     * @param oldBalance - normalized amount of all tokens before the deposit
     * @param oldTokenBlance - normalized amount of the balance of the token to be deposited in the pool
     * @param softWeight - percentage that will incur penalty if the resulting token percentage is greater
     * @param hardWeight - maximum percentage of the token
     */
    function _getMintAmount(
        uint256 bTokenAmountNormalized,
        uint256 oldBalance,
        uint256 oldTokenBalance,
        uint256 softWeight,
        uint256 hardWeight
    )
        internal
        pure
        returns (uint256 s)
    {
        /* Evaluate new percentage */
        uint256 newBalance = oldBalance.add(bTokenAmountNormalized);
        uint256 newTokenBalance = oldTokenBalance.add(bTokenAmountNormalized);

        /* If new percentage <= soft weight, no penalty */
        if (newTokenBalance.mul(W_ONE) <= softWeight.mul(newBalance)) {
            return bTokenAmountNormalized;
        }

        require (
            newTokenBalance.mul(W_ONE) <= hardWeight.mul(newBalance),
            "mint: new percentage exceeds hard weight"
        );

        s = 0;
        /* if new percentage <= soft weight, get the beginning of integral with penalty. */
        if (oldTokenBalance.mul(W_ONE) <= softWeight.mul(oldBalance)) {
            s = oldBalance.mul(softWeight).sub(oldTokenBalance.mul(W_ONE)).div(W_ONE.sub(softWeight));
        }

        // bx + (tx - bx) * (w - 1) / (w - v) + (S - x) * ln((S + tx) / (S + bx)) / (w - v)
        uint256 t;
        { // avoid stack too deep error
        uint256 ldelta = _log(newBalance.mul(W_ONE).div(oldBalance.add(s)));
        t = oldBalance.sub(oldTokenBalance).mul(ldelta);
        }
        t = t.sub(bTokenAmountNormalized.sub(s).mul(W_ONE.sub(hardWeight)));
        t = t.div(hardWeight.sub(softWeight));
        s = s.add(t);

        require(s <= bTokenAmountNormalized, "penalty should be positive");
    }

    /*
     * @dev Given the token id and the amount to be deposited, return the amount of lp token
     */
    function getMintAmount(
        uint256 bTokenIdx,
        uint256 bTokenAmount
    )
        public
        view
        returns (uint256 lpTokenAmount)
    {
        require(bTokenAmount > 0, "Amount must be greater than 0");

        uint256 info = _tokenInfos[bTokenIdx];
        require(info != 0, "Backed token is not found!");

        // Obtain normalized balances
        uint256 bTokenAmountNormalized = bTokenAmount.mul(_normalizeBalance(info));
        // Gas saving: Use cached totalBalance with accrued interest since last rebalance.
        uint256 totalBalance = _totalBalance;
        uint256 sTokenAmount = _getMintAmount(
            bTokenAmountNormalized,
            totalBalance,
            _getBalance(info),
            _getSoftWeight(info),
            _getHardWeight(info)
        );

        return sTokenAmount.mul(totalSupply()).div(totalBalance);
    }

    /*
     * @dev Given the token id and the amount to be deposited, mint lp token
     */
    function mint(
        uint256 bTokenIdx,
        uint256 bTokenAmount,
        uint256 lpTokenMintedMin
    )
        external
        nonReentrantAndUnpausedV1
    {
        uint256 lpTokenAmount = getMintAmount(bTokenIdx, bTokenAmount);
        require(
            lpTokenAmount >= lpTokenMintedMin,
            "lpToken minted should >= minimum lpToken asked"
        );

        _transferIn(_tokenInfos[bTokenIdx], bTokenAmount);
        _mint(msg.sender, lpTokenAmount);
        emit Mint(msg.sender, bTokenAmount, lpTokenAmount);
    }

    /**************************************************************************************
     * Methods for redeeming LP tokens
     *************************************************************************************/

    /*
     * @dev Return number of sUSD that is needed to redeem corresponding amount of token for another
     *      token
     * Withdrawing a token will result in increased percentage of other tokens, where
     * the function is used to calculate the penalty incured by the increase of one token.
     * @param totalBalance - normalized amount of the sum of all tokens
     * @param tokenBlance - normalized amount of the balance of a non-withdrawn token
     * @param redeemAount - normalized amount of the token to be withdrawn
     * @param softWeight - percentage that will incur penalty if the resulting token percentage is greater
     * @param hardWeight - maximum percentage of the token
     */
    function _redeemPenaltyFor(
        uint256 totalBalance,
        uint256 tokenBalance,
        uint256 redeemAmount,
        uint256 softWeight,
        uint256 hardWeight
    )
        internal
        pure
        returns (uint256)
    {
        uint256 newTotalBalance = totalBalance.sub(redeemAmount);

        /* Soft weight is satisfied.  No penalty is incurred */
        if (tokenBalance.mul(W_ONE) <= newTotalBalance.mul(softWeight)) {
            return 0;
        }

        require (
            tokenBalance.mul(W_ONE) <= newTotalBalance.mul(hardWeight),
            "redeem: hard-limit weight is broken"
        );

        uint256 bx = 0;
        // Evaluate the beginning of the integral for broken soft weight
        if (tokenBalance.mul(W_ONE) < totalBalance.mul(softWeight)) {
            bx = totalBalance.sub(tokenBalance.mul(W_ONE).div(softWeight));
        }

        // x * (w - v) / w / w * ln(1 + (tx - bx) * w / (w * (S - tx) - x)) - (tx - bx) * v / w
        uint256 tdelta = tokenBalance.mul(
            _log(W_ONE.add(redeemAmount.sub(bx).mul(hardWeight).div(hardWeight.mul(newTotalBalance).div(W_ONE).sub(tokenBalance)))));
        uint256 s1 = tdelta.mul(hardWeight.sub(softWeight))
            .div(hardWeight).div(hardWeight);
        uint256 s2 = redeemAmount.sub(bx).mul(softWeight).div(hardWeight);
        return s1.sub(s2);
    }

    /*
     * @dev Return number of sUSD that is needed to redeem corresponding amount of token
     * Withdrawing a token will result in increased percentage of other tokens, where
     * the function is used to calculate the penalty incured by the increase.
     * @param bTokenIdx - token id to be withdrawn
     * @param totalBalance - normalized amount of the sum of all tokens
     * @param balances - normalized amount of the balance of each token
     * @param softWeights - percentage that will incur penalty if the resulting token percentage is greater
     * @param hardWeights - maximum percentage of the token
     * @param redeemAount - normalized amount of the token to be withdrawn
     */
    function _redeemPenaltyForAll(
        uint256 bTokenIdx,
        uint256 totalBalance,
        uint256[] memory balances,
        uint256[] memory softWeights,
        uint256[] memory hardWeights,
        uint256 redeemAmount
    )
        internal
        pure
        returns (uint256)
    {
        uint256 s = 0;
        for (uint256 k = 0; k < balances.length; k++) {
            if (k == bTokenIdx) {
                continue;
            }

            s = s.add(
                _redeemPenaltyFor(totalBalance, balances[k], redeemAmount, softWeights[k], hardWeights[k]));
        }
        return s;
    }

    /*
     * @dev Calculate the derivative of the penalty function.
     * Same parameters as _redeemPenaltyFor.
     */
    function _redeemPenaltyDerivativeForOne(
        uint256 totalBalance,
        uint256 tokenBalance,
        uint256 redeemAmount,
        uint256 softWeight,
        uint256 hardWeight
    )
        internal
        pure
        returns (uint256)
    {
        uint256 dfx = W_ONE;
        uint256 newTotalBalance = totalBalance.sub(redeemAmount);

        /* Soft weight is satisfied.  No penalty is incurred */
        if (tokenBalance.mul(W_ONE) <= newTotalBalance.mul(softWeight)) {
            return dfx;
        }

        // dx = dx + x * (w - v) / (w * (S - tx) - x) / w - v / w
        return dfx.add(tokenBalance.mul(hardWeight.sub(softWeight))
            .div(hardWeight.mul(newTotalBalance).div(W_ONE).sub(tokenBalance)))
            .sub(softWeight.mul(W_ONE).div(hardWeight));
    }

    /*
     * @dev Calculate the derivative of the penalty function.
     * Same parameters as _redeemPenaltyForAll.
     */
    function _redeemPenaltyDerivativeForAll(
        uint256 bTokenIdx,
        uint256 totalBalance,
        uint256[] memory balances,
        uint256[] memory softWeights,
        uint256[] memory hardWeights,
        uint256 redeemAmount
    )
        internal
        pure
        returns (uint256)
    {
        uint256 dfx = W_ONE;
        uint256 newTotalBalance = totalBalance.sub(redeemAmount);
        for (uint256 k = 0; k < balances.length; k++) {
            if (k == bTokenIdx) {
                continue;
            }

            /* Soft weight is satisfied.  No penalty is incurred */
            uint256 softWeight = softWeights[k];
            uint256 balance = balances[k];
            if (balance.mul(W_ONE) <= newTotalBalance.mul(softWeight)) {
                continue;
            }

            // dx = dx + x * (w - v) / (w * (S - tx) - x) / w - v / w
            uint256 hardWeight = hardWeights[k];
            dfx = dfx.add(balance.mul(hardWeight.sub(softWeight))
                .div(hardWeight.mul(newTotalBalance).div(W_ONE).sub(balance)))
                .sub(softWeight.mul(W_ONE).div(hardWeight));
        }
        return dfx;
    }

    /*
     * @dev Given the amount of sUSD to be redeemed, find the max token can be withdrawn
     * This function is for swap only.
     * @param tidOutBalance - the balance of the token to be withdrawn
     * @param totalBalance - total balance of all tokens
     * @param tidInBalance - the balance of the token to be deposited
     * @param sTokenAmount - the amount of sUSD to be redeemed
     * @param softWeight/hardWeight - normalized weights for the token to be withdrawn.
     */
    function _redeemFindOne(
        uint256 tidOutBalance,
        uint256 totalBalance,
        uint256 tidInBalance,
        uint256 sTokenAmount,
        uint256 softWeight,
        uint256 hardWeight
    )
        internal
        pure
        returns (uint256)
    {
        uint256 redeemAmountNormalized = Math.min(
            sTokenAmount,
            tidOutBalance.mul(999).div(1000)
        );

        for (uint256 i = 0; i < 256; i++) {
            uint256 sNeeded = redeemAmountNormalized.add(
                _redeemPenaltyFor(
                    totalBalance,
                    tidInBalance,
                    redeemAmountNormalized,
                    softWeight,
                    hardWeight
                ));
            uint256 fx = 0;

            if (sNeeded > sTokenAmount) {
                fx = sNeeded - sTokenAmount;
            } else {
                fx = sTokenAmount - sNeeded;
            }

            // penalty < 1e-5 of out amount
            if (fx < redeemAmountNormalized / 100000) {
                require(redeemAmountNormalized <= sTokenAmount, "Redeem error: out amount > lp amount");
                require(redeemAmountNormalized <= tidOutBalance, "Redeem error: insufficient balance");
                return redeemAmountNormalized;
            }

            uint256 dfx = _redeemPenaltyDerivativeForOne(
                totalBalance,
                tidInBalance,
                redeemAmountNormalized,
                softWeight,
                hardWeight
            );

            if (sNeeded > sTokenAmount) {
                redeemAmountNormalized = redeemAmountNormalized.sub(fx.mul(W_ONE).div(dfx));
            } else {
                redeemAmountNormalized = redeemAmountNormalized.add(fx.mul(W_ONE).div(dfx));
            }
        }
        require (false, "cannot find proper resolution of fx");
    }

    /*
     * @dev Given the amount of sUSD token to be redeemed, find the max token can be withdrawn
     * @param bTokenIdx - the id of the token to be withdrawn
     * @param sTokenAmount - the amount of sUSD token to be redeemed
     * @param totalBalance - total balance of all tokens
     * @param balances/softWeight/hardWeight - normalized balances/weights of all tokens
     */
    function _redeemFind(
        uint256 bTokenIdx,
        uint256 sTokenAmount,
        uint256 totalBalance,
        uint256[] memory balances,
        uint256[] memory softWeights,
        uint256[] memory hardWeights
    )
        internal
        pure
        returns (uint256)
    {
        uint256 bTokenAmountNormalized = Math.min(
            sTokenAmount,
            balances[bTokenIdx].mul(999).div(1000)
        );

        for (uint256 i = 0; i < 256; i++) {
            uint256 sNeeded = bTokenAmountNormalized.add(
                _redeemPenaltyForAll(
                    bTokenIdx,
                    totalBalance,
                    balances,
                    softWeights,
                    hardWeights,
                    bTokenAmountNormalized
                ));
            uint256 fx = 0;

            if (sNeeded > sTokenAmount) {
                fx = sNeeded - sTokenAmount;
            } else {
                fx = sTokenAmount - sNeeded;
            }

            // penalty < 1e-5 of out amount
            if (fx < bTokenAmountNormalized / 100000) {
                require(bTokenAmountNormalized <= sTokenAmount, "Redeem error: out amount > lp amount");
                require(bTokenAmountNormalized <= balances[bTokenIdx], "Redeem error: insufficient balance");
                return bTokenAmountNormalized;
            }

            uint256 dfx = _redeemPenaltyDerivativeForAll(
                bTokenIdx,
                totalBalance,
                balances,
                softWeights,
                hardWeights,
                bTokenAmountNormalized
            );

            if (sNeeded > sTokenAmount) {
                bTokenAmountNormalized = bTokenAmountNormalized.sub(fx.mul(W_ONE).div(dfx));
            } else {
                bTokenAmountNormalized = bTokenAmountNormalized.add(fx.mul(W_ONE).div(dfx));
            }
        }
        require (false, "cannot find proper resolution of fx");
    }

    /*
     * @dev Given token id and LP token amount, return the max amount of token can be withdrawn
     * @param tid - the id of the token to be withdrawn
     * @param lpTokenAmount - the amount of LP token
     */
    function _getRedeemByLpTokenAmount(
        uint256 tid,
        uint256 lpTokenAmount
    )
        internal
        view
        returns (uint256 bTokenAmount, uint256 totalBalance, uint256 adminFee)
    {
        require(lpTokenAmount > 0, "Amount must be greater than 0");

        uint256 info = _tokenInfos[tid];
        require(info != 0, "Backed token is not found!");

        // Obtain normalized balances.
        // Gas saving: Use cached balances/totalBalance without accrued interest since last rebalance.
        uint256[] memory balances;
        uint256[] memory softWeights;
        uint256[] memory hardWeights;
        (balances, softWeights, hardWeights, totalBalance) = _getBalancesAndWeights();
        bTokenAmount = _redeemFind(
            tid,
            lpTokenAmount.mul(totalBalance).div(totalSupply()),
            totalBalance,
            balances,
            softWeights,
            hardWeights
        ).div(_normalizeBalance(info));
        uint256 fee = bTokenAmount.mul(_redeemFee).div(W_ONE);
        adminFee = fee.mul(_adminFeePct).div(W_ONE);
        bTokenAmount = bTokenAmount.sub(fee);
    }

    function getRedeemByLpTokenAmount(
        uint256 tid,
        uint256 lpTokenAmount
    )
        public
        view
        returns (uint256 bTokenAmount)
    {
        (bTokenAmount,,) = _getRedeemByLpTokenAmount(tid, lpTokenAmount);

    }

    function redeemByLpToken(
        uint256 bTokenIdx,
        uint256 lpTokenAmount,
        uint256 bTokenMin
    )
        external
        nonReentrantAndUnpausedV1
    {
        (uint256 bTokenAmount, uint256 totalBalance, uint256 adminFee) = _getRedeemByLpTokenAmount(
            bTokenIdx,
            lpTokenAmount
        );
        require(bTokenAmount >= bTokenMin, "bToken returned < min bToken asked");

        // Make sure _totalBalance == sum(balances)
        _collectReward(totalBalance);

        _burn(msg.sender, lpTokenAmount);
        _transferOut(_tokenInfos[bTokenIdx], bTokenAmount, adminFee);

        emit Redeem(msg.sender, bTokenAmount, lpTokenAmount);
    }

    /* @dev Redeem a specific token from the pool.
     * Fee will be incured.  Will incur penalty if the pool is unbalanced.
     */
    function redeem(
        uint256 bTokenIdx,
        uint256 bTokenAmount,
        uint256 lpTokenBurnedMax
    )
        external
        nonReentrantAndUnpausedV1
    {
        require(bTokenAmount > 0, "Amount must be greater than 0");

        uint256 info = _tokenInfos[bTokenIdx];
        require (info != 0, "Backed token is not found!");

        // Obtain normalized balances.
        // Gas saving: Use cached balances/totalBalance without accrued interest since last rebalance.
        (
            uint256[] memory balances,
            uint256[] memory softWeights,
            uint256[] memory hardWeights,
            uint256 totalBalance
        ) = _getBalancesAndWeights();
        uint256 bTokenAmountNormalized = bTokenAmount.mul(_normalizeBalance(info));
        require(balances[bTokenIdx] >= bTokenAmountNormalized, "Insufficient token to redeem");

        _collectReward(totalBalance);

        uint256 lpAmount = bTokenAmountNormalized.add(
            _redeemPenaltyForAll(
                bTokenIdx,
                totalBalance,
                balances,
                softWeights,
                hardWeights,
                bTokenAmountNormalized
            )).mul(totalSupply()).div(totalBalance);
        require(lpAmount <= lpTokenBurnedMax, "burned token should <= maximum lpToken offered");

        _burn(msg.sender, lpAmount);

        /* Transfer out the token after deducting the fee.  Rebalance cash reserve if needed */
        uint256 fee = bTokenAmount.mul(_redeemFee).div(W_ONE);
        _transferOut(
            _tokenInfos[bTokenIdx],
            bTokenAmount.sub(fee),
            fee.mul(_adminFeePct).div(W_ONE)
        );

        emit Redeem(msg.sender, bTokenAmount, lpAmount);
    }

    /**************************************************************************************
     * Methods for swapping tokens
     *************************************************************************************/

    /*
     * @dev Return the maximum amount of token can be withdrawn after depositing another token.
     * @param bTokenIdIn - the id of the token to be deposited
     * @param bTokenIdOut - the id of the token to be withdrawn
     * @param bTokenInAmount - the amount (unnormalized) of the token to be deposited
     */
    function getSwapAmount(
        uint256 bTokenIdxIn,
        uint256 bTokenIdxOut,
        uint256 bTokenInAmount
    )
        external
        view
        returns (uint256 bTokenOutAmount)
    {
        uint256 infoIn = _tokenInfos[bTokenIdxIn];
        uint256 infoOut = _tokenInfos[bTokenIdxOut];

        (bTokenOutAmount,) = _getSwapAmount(infoIn, infoOut, bTokenInAmount);
    }

    function _getSwapAmount(
        uint256 infoIn,
        uint256 infoOut,
        uint256 bTokenInAmount
    )
        internal
        view
        returns (uint256 bTokenOutAmount, uint256 adminFee)
    {
        require(bTokenInAmount > 0, "Amount must be greater than 0");
        require(infoIn != 0, "Backed token is not found!");
        require(infoOut != 0, "Backed token is not found!");
        require (infoIn != infoOut, "Tokens for swap must be different!");

        // Gas saving: Use cached totalBalance without accrued interest since last rebalance.
        // Here we assume that the interest earned from the underlying platform is too small to
        // impact the result significantly.
        uint256 totalBalance = _totalBalance;
        uint256 tidInBalance = _getBalance(infoIn);
        uint256 sMinted = 0;
        uint256 softWeight = _getSoftWeight(infoIn);
        uint256 hardWeight = _getHardWeight(infoIn);

        { // avoid stack too deep error
        uint256 bTokenInAmountNormalized = bTokenInAmount.mul(_normalizeBalance(infoIn));
        sMinted = _getMintAmount(
            bTokenInAmountNormalized,
            totalBalance,
            tidInBalance,
            softWeight,
            hardWeight
        );

        totalBalance = totalBalance.add(bTokenInAmountNormalized);
        tidInBalance = tidInBalance.add(bTokenInAmountNormalized);
        }
        uint256 tidOutBalance = _getBalance(infoOut);

        // Find the bTokenOutAmount, only account for penalty from bTokenIdxIn
        // because other tokens should not have penalty since
        // bTokenOutAmount <= sMinted <= bTokenInAmount (normalized), and thus
        // for other tokens, the percentage decreased by bTokenInAmount will be
        // >= the percetnage increased by bTokenOutAmount.
        bTokenOutAmount = _redeemFindOne(
            tidOutBalance,
            totalBalance,
            tidInBalance,
            sMinted,
            softWeight,
            hardWeight
        ).div(_normalizeBalance(infoOut));
        uint256 fee = bTokenOutAmount.mul(_swapFee).div(W_ONE);
        adminFee = fee.mul(_adminFeePct).div(W_ONE);
        bTokenOutAmount = bTokenOutAmount.sub(fee);
    }

    /*
     * @dev Swap a token to another.
     * @param bTokenIdIn - the id of the token to be deposited
     * @param bTokenIdOut - the id of the token to be withdrawn
     * @param bTokenInAmount - the amount (unnormalized) of the token to be deposited
     * @param bTokenOutMin - the mininum amount (unnormalized) token that is expected to be withdrawn
     */
    function swap(
        uint256 bTokenIdxIn,
        uint256 bTokenIdxOut,
        uint256 bTokenInAmount,
        uint256 bTokenOutMin
    )
        external
        nonReentrantAndUnpausedV1
    {
        uint256 infoIn = _tokenInfos[bTokenIdxIn];
        uint256 infoOut = _tokenInfos[bTokenIdxOut];
        (
            uint256 bTokenOutAmount,
            uint256 adminFee
        ) = _getSwapAmount(infoIn, infoOut, bTokenInAmount);
        require(bTokenOutAmount >= bTokenOutMin, "Returned bTokenAmount < asked");

        _transferIn(infoIn, bTokenInAmount);
        _transferOut(infoOut, bTokenOutAmount, adminFee);

        emit Swap(
            msg.sender,
            bTokenIdxIn,
            bTokenIdxOut,
            bTokenInAmount,
            bTokenOutAmount
        );
    }

    /*
     * @dev Swap tokens given all token amounts
     * The amounts are pre-fee amounts, and the user will provide max fee expected.
     * Currently, do not support penalty.
     * @param inOutFlag - 0 means deposit, and 1 means withdraw with highest bit indicating mint/burn lp token
     * @param lpTokenMintedMinOrBurnedMax - amount of lp token to be minted/burnt
     * @param maxFee - maximum percentage of fee will be collected for withdrawal
     * @param amounts - list of unnormalized amounts of each token
     */
    function swapAll(
        uint256 inOutFlag,
        uint256 lpTokenMintedMinOrBurnedMax,
        uint256 maxFee,
        uint256[] calldata amounts
    )
        external
        nonReentrantAndUnpausedV1
    {
        // Gas saving: Use cached balances/totalBalance without accrued interest since last rebalance.
        (
            uint256[] memory balances,
            uint256[] memory infos,
            uint256 oldTotalBalance
        ) = _getBalancesAndInfos();
        // Make sure _totalBalance = oldTotalBalance = sum(_getBalance()'s)
        _collectReward(oldTotalBalance);

        require (amounts.length == balances.length, "swapAll amounts length != ntokens");
        uint256 newTotalBalance = 0;
        uint256 depositAmount = 0;

        { // avoid stack too deep error
        uint256[] memory newBalances = new uint256[](balances.length);
        for (uint256 i = 0; i < balances.length; i++) {
            uint256 normalizedAmount = _normalizeBalance(infos[i]).mul(amounts[i]);
            if (((inOutFlag >> i) & 1) == 0) {
                // In
                depositAmount = depositAmount.add(normalizedAmount);
                newBalances[i] = balances[i].add(normalizedAmount);
            } else {
                // Out
                newBalances[i] = balances[i].sub(normalizedAmount);
            }
            newTotalBalance = newTotalBalance.add(newBalances[i]);
        }

        for (uint256 i = 0; i < balances.length; i++) {
            // If there is no mint/redeem, and the new total balance >= old one,
            // then the weight must be non-increasing and thus there is no penalty.
            if (amounts[i] == 0 && newTotalBalance >= oldTotalBalance) {
                continue;
            }

            /*
             * Accept the new amount if the following is satisfied
             *     np_i <= max(p_i, w_i)
             */
            if (newBalances[i].mul(W_ONE) <= newTotalBalance.mul(_getSoftWeight(infos[i]))) {
                continue;
            }

            // If no tokens in the pool, only weight contraints will be applied.
            require(
                oldTotalBalance != 0 &&
                newBalances[i].mul(oldTotalBalance) <= newTotalBalance.mul(balances[i]),
                "penalty is not supported in swapAll now"
            );
        }
        }

        // Calculate fee rate and mint/burn LP tokens
        uint256 feeRate = 0;
        uint256 lpMintedOrBurned = 0;
        if (newTotalBalance == oldTotalBalance) {
            // Swap only.  No need to burn or mint.
            lpMintedOrBurned = 0;
            feeRate = _swapFee;
        } else if (((inOutFlag >> 255) & 1) == 0) {
            require (newTotalBalance >= oldTotalBalance, "swapAll mint: new total balance must >= old total balance");
            lpMintedOrBurned = newTotalBalance.sub(oldTotalBalance).mul(totalSupply()).div(oldTotalBalance);
            require(lpMintedOrBurned >= lpTokenMintedMinOrBurnedMax, "LP tokend minted < asked");
            feeRate = _swapFee;
            _mint(msg.sender, lpMintedOrBurned);
        } else {
            require (newTotalBalance <= oldTotalBalance, "swapAll redeem: new total balance must <= old total balance");
            lpMintedOrBurned = oldTotalBalance.sub(newTotalBalance).mul(totalSupply()).div(oldTotalBalance);
            require(lpMintedOrBurned <= lpTokenMintedMinOrBurnedMax, "LP tokend burned > offered");
            uint256 withdrawAmount = oldTotalBalance - newTotalBalance;
            /*
             * The fee is determined by swapAmount * swap_fee + withdrawAmount * withdraw_fee,
             * where swapAmount = depositAmount if withdrawAmount >= 0.
             */
            feeRate = _swapFee.mul(depositAmount).add(_redeemFee.mul(withdrawAmount)).div(depositAmount + withdrawAmount);
            _burn(msg.sender, lpMintedOrBurned);
        }
        emit SwapAll(msg.sender, amounts, inOutFlag, lpMintedOrBurned);

        require (feeRate <= maxFee, "swapAll fee is greater than max fee user offered");
        for (uint256 i = 0; i < balances.length; i++) {
            if (amounts[i] == 0) {
                continue;
            }

            if (((inOutFlag >> i) & 1) == 0) {
                // In
                _transferIn(infos[i], amounts[i]);
            } else {
                // Out (with fee)
                uint256 fee = amounts[i].mul(feeRate).div(W_ONE);
                uint256 adminFee = fee.mul(_adminFeePct).div(W_ONE);
                _transferOut(infos[i], amounts[i].sub(fee), adminFee);
            }
        }
    }

    /**************************************************************************************
     * Methods for others
     *************************************************************************************/

    /* @dev Collect admin fee so that _totalBalance == sum(_getBalances()'s) */
    function _collectReward(uint256 totalBalance) internal {
        uint256 oldTotalBalance = _totalBalance;
        if (totalBalance != oldTotalBalance) {
            if (totalBalance > oldTotalBalance) {
                _mint(_rewardCollector, totalSupply().mul(totalBalance - oldTotalBalance).div(oldTotalBalance));
            }
            _totalBalance = totalBalance;
        }
    }

    /* @dev Collect admin fee.  Can be called by anyone */
    function collectReward()
        external
        nonReentrantAndUnpausedV1
    {
        (,,,uint256 totalBalance) = _getBalancesAndWeights();
        _collectReward(totalBalance);
    }

    function getTokenStats(uint256 bTokenIdx)
        public
        view
        returns (uint256 softWeight, uint256 hardWeight, uint256 balance, uint256 decimals)
    {
        require(bTokenIdx < _ntokens, "Backed token is not found!");

        uint256 info = _tokenInfos[bTokenIdx];

        balance = _getBalance(info).div(_normalizeBalance(info));
        softWeight = _getSoftWeight(info);
        hardWeight = _getHardWeight(info);
        decimals = ERC20(address(info)).decimals();
    }
}

// File: contracts/Root.sol

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;




contract Root is UpgradeableExtension, SmoothyV1 {
    constructor(
        address[] memory tokens,
        address[] memory yTokens,
        uint256[] memory decMultipliers,
        uint256[] memory softWeights,
        uint256[] memory hardWeights
    )
        public
        UpgradeableExtension()
        SmoothyV1(tokens, yTokens, decMultipliers, softWeights, hardWeights)
    { }

    function upgradeTo(address newImplementation) external onlyOwner {
        _upgradeTo(newImplementation);
    }
}