/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

pragma solidity ^0.7.6;

// SPDX-License-Identifier: MIT
// Source code: https://github.com/DeCash-Official/smart-contracts

interface DeCashProxyInterface {
    function initialize(string memory _tokenName, address _tokenAddr) external;

    function upgrade(address _new) external;
}

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) =
            target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

interface DeCashStorageInterface {
    // Getters
    function getAddress(bytes32 _key) external view returns (address);

    function getUint(bytes32 _key) external view returns (uint256);

    function getString(bytes32 _key) external view returns (string memory);

    function getBytes(bytes32 _key) external view returns (bytes memory);

    function getBool(bytes32 _key) external view returns (bool);

    function getInt(bytes32 _key) external view returns (int256);

    function getBytes32(bytes32 _key) external view returns (bytes32);

    // Setters
    function setAddress(bytes32 _key, address _value) external;

    function setUint(bytes32 _key, uint256 _value) external;

    function setString(bytes32 _key, string calldata _value) external;

    function setBytes(bytes32 _key, bytes calldata _value) external;

    function setBool(bytes32 _key, bool _value) external;

    function setInt(bytes32 _key, int256 _value) external;

    function setBytes32(bytes32 _key, bytes32 _value) external;

    // Deleters
    function deleteAddress(bytes32 _key) external;

    function deleteUint(bytes32 _key) external;

    function deleteString(bytes32 _key) external;

    function deleteBytes(bytes32 _key) external;

    function deleteBool(bytes32 _key) external;

    function deleteInt(bytes32 _key) external;

    function deleteBytes32(bytes32 _key) external;
}

/// @title Base settings / modifiers for each contract in DeCash Token (Credits David Rugendyke/Rocket Pool)
/// @author Fabrizio Amodio (ZioFabry)

abstract contract DeCashBase {
    // Version of the contract
    uint8 public version;

    // The main storage contract where primary persistant storage is maintained
    DeCashStorageInterface internal _decashStorage = DeCashStorageInterface(0);

    /**
     * @dev Throws if called by any sender that doesn't match one of the supplied contract or is the latest version of that contract
     */
    modifier onlyLatestContract(
        string memory _contractName,
        address _contractAddress
    ) {
        require(
            _contractAddress ==
                _getAddress(
                    keccak256(
                        abi.encodePacked("contract.address", _contractName)
                    )
                ),
            "Invalid or outdated contract"
        );
        _;
    }

    modifier onlyOwner() {
        require(_isOwner(msg.sender), "Account is not the owner");
        _;
    }
    modifier onlyAdmin() {
        require(_isAdmin(msg.sender), "Account is not an admin");
        _;
    }
    modifier onlySuperUser() {
        require(_isSuperUser(msg.sender), "Account is not a super user");
        _;
    }
    modifier onlyDelegator(address _address) {
        require(_isDelegator(_address), "Account is not a delegator");
        _;
    }
    modifier onlyFeeRecipient(address _address) {
        require(_isFeeRecipient(_address), "Account is not a fee recipient");
        _;
    }
    modifier onlyRole(string memory _role) {
        require(_roleHas(_role, msg.sender), "Account does not match the role");
        _;
    }

    /// @dev Set the main DeCash Storage address
    constructor(address _decashStorageAddress) {
        // Update the contract address
        _decashStorage = DeCashStorageInterface(_decashStorageAddress);
    }

    function isOwner(address _address) external view returns (bool) {
        return _isOwner(_address);
    }

    function isAdmin(address _address) external view returns (bool) {
        return _isAdmin(_address);
    }

    function isSuperUser(address _address) external view returns (bool) {
        return _isSuperUser(_address);
    }

    function isDelegator(address _address) external view returns (bool) {
        return _isDelegator(_address);
    }

    function isFeeRecipient(address _address) external view returns (bool) {
        return _isFeeRecipient(_address);
    }

    function isBlacklisted(address _address) external view returns (bool) {
        return _isBlacklisted(_address);
    }

    /// @dev Get the address of a network contract by name
    function _getContractAddress(string memory _contractName)
        internal
        view
        returns (address)
    {
        // Get the current contract address
        address contractAddress =
            _getAddress(
                keccak256(abi.encodePacked("contract.address", _contractName))
            );
        // Check it
        require(contractAddress != address(0x0), "Contract not found");
        // Return
        return contractAddress;
    }

    /// @dev Get the name of a network contract by address
    function _getContractName(address _contractAddress)
        internal
        view
        returns (string memory)
    {
        // Get the contract name
        string memory contractName =
            _getString(
                keccak256(abi.encodePacked("contract.name", _contractAddress))
            );
        // Check it
        require(
            keccak256(abi.encodePacked(contractName)) !=
                keccak256(abi.encodePacked("")),
            "Contract not found"
        );
        // Return
        return contractName;
    }

    /// @dev Role Management
    function _roleHas(string memory _role, address _address)
        internal
        view
        returns (bool)
    {
        return
            _getBool(
                keccak256(abi.encodePacked("access.role", _role, _address))
            );
    }

    function _isOwner(address _address) internal view returns (bool) {
        return _roleHas("owner", _address);
    }

    function _isAdmin(address _address) internal view returns (bool) {
        return _roleHas("admin", _address);
    }

    function _isSuperUser(address _address) internal view returns (bool) {
        return _roleHas("admin", _address) || _isOwner(_address);
    }

    function _isDelegator(address _address) internal view returns (bool) {
        return _roleHas("delegator", _address) || _isOwner(_address);
    }

    function _isFeeRecipient(address _address) internal view returns (bool) {
        return _roleHas("fee", _address) || _isOwner(_address);
    }

    function _isBlacklisted(address _address) internal view returns (bool) {
        return _roleHas("blacklisted", _address) && !_isOwner(_address);
    }

    /// @dev Storage get methods
    function _getAddress(bytes32 _key) internal view returns (address) {
        return _decashStorage.getAddress(_key);
    }

    function _getUint(bytes32 _key) internal view returns (uint256) {
        return _decashStorage.getUint(_key);
    }

    function _getString(bytes32 _key) internal view returns (string memory) {
        return _decashStorage.getString(_key);
    }

    function _getBytes(bytes32 _key) internal view returns (bytes memory) {
        return _decashStorage.getBytes(_key);
    }

    function _getBool(bytes32 _key) internal view returns (bool) {
        return _decashStorage.getBool(_key);
    }

    function _getInt(bytes32 _key) internal view returns (int256) {
        return _decashStorage.getInt(_key);
    }

    function _getBytes32(bytes32 _key) internal view returns (bytes32) {
        return _decashStorage.getBytes32(_key);
    }

    function _getAddressS(string memory _key) internal view returns (address) {
        return _decashStorage.getAddress(keccak256(abi.encodePacked(_key)));
    }

    function _getUintS(string memory _key) internal view returns (uint256) {
        return _decashStorage.getUint(keccak256(abi.encodePacked(_key)));
    }

    function _getStringS(string memory _key)
        internal
        view
        returns (string memory)
    {
        return _decashStorage.getString(keccak256(abi.encodePacked(_key)));
    }

    function _getBytesS(string memory _key)
        internal
        view
        returns (bytes memory)
    {
        return _decashStorage.getBytes(keccak256(abi.encodePacked(_key)));
    }

    function _getBoolS(string memory _key) internal view returns (bool) {
        return _decashStorage.getBool(keccak256(abi.encodePacked(_key)));
    }

    function _getIntS(string memory _key) internal view returns (int256) {
        return _decashStorage.getInt(keccak256(abi.encodePacked(_key)));
    }

    function _getBytes32S(string memory _key) internal view returns (bytes32) {
        return _decashStorage.getBytes32(keccak256(abi.encodePacked(_key)));
    }

    /// @dev Storage set methods
    function _setAddress(bytes32 _key, address _value) internal {
        _decashStorage.setAddress(_key, _value);
    }

    function _setUint(bytes32 _key, uint256 _value) internal {
        _decashStorage.setUint(_key, _value);
    }

    function _setString(bytes32 _key, string memory _value) internal {
        _decashStorage.setString(_key, _value);
    }

    function _setBytes(bytes32 _key, bytes memory _value) internal {
        _decashStorage.setBytes(_key, _value);
    }

    function _setBool(bytes32 _key, bool _value) internal {
        _decashStorage.setBool(_key, _value);
    }

    function _setInt(bytes32 _key, int256 _value) internal {
        _decashStorage.setInt(_key, _value);
    }

    function _setBytes32(bytes32 _key, bytes32 _value) internal {
        _decashStorage.setBytes32(_key, _value);
    }

    function _setAddressS(string memory _key, address _value) internal {
        _decashStorage.setAddress(keccak256(abi.encodePacked(_key)), _value);
    }

    function _setUintS(string memory _key, uint256 _value) internal {
        _decashStorage.setUint(keccak256(abi.encodePacked(_key)), _value);
    }

    function _setStringS(string memory _key, string memory _value) internal {
        _decashStorage.setString(keccak256(abi.encodePacked(_key)), _value);
    }

    function _setBytesS(string memory _key, bytes memory _value) internal {
        _decashStorage.setBytes(keccak256(abi.encodePacked(_key)), _value);
    }

    function _setBoolS(string memory _key, bool _value) internal {
        _decashStorage.setBool(keccak256(abi.encodePacked(_key)), _value);
    }

    function _setIntS(string memory _key, int256 _value) internal {
        _decashStorage.setInt(keccak256(abi.encodePacked(_key)), _value);
    }

    function _setBytes32S(string memory _key, bytes32 _value) internal {
        _decashStorage.setBytes32(keccak256(abi.encodePacked(_key)), _value);
    }

    /// @dev Storage delete methods
    function _deleteAddress(bytes32 _key) internal {
        _decashStorage.deleteAddress(_key);
    }

    function _deleteUint(bytes32 _key) internal {
        _decashStorage.deleteUint(_key);
    }

    function _deleteString(bytes32 _key) internal {
        _decashStorage.deleteString(_key);
    }

    function _deleteBytes(bytes32 _key) internal {
        _decashStorage.deleteBytes(_key);
    }

    function _deleteBool(bytes32 _key) internal {
        _decashStorage.deleteBool(_key);
    }

    function _deleteInt(bytes32 _key) internal {
        _decashStorage.deleteInt(_key);
    }

    function _deleteBytes32(bytes32 _key) internal {
        _decashStorage.deleteBytes32(_key);
    }

    function _deleteAddressS(string memory _key) internal {
        _decashStorage.deleteAddress(keccak256(abi.encodePacked(_key)));
    }

    function _deleteUintS(string memory _key) internal {
        _decashStorage.deleteUint(keccak256(abi.encodePacked(_key)));
    }

    function _deleteStringS(string memory _key) internal {
        _decashStorage.deleteString(keccak256(abi.encodePacked(_key)));
    }

    function _deleteBytesS(string memory _key) internal {
        _decashStorage.deleteBytes(keccak256(abi.encodePacked(_key)));
    }

    function _deleteBoolS(string memory _key) internal {
        _decashStorage.deleteBool(keccak256(abi.encodePacked(_key)));
    }

    function _deleteIntS(string memory _key) internal {
        _decashStorage.deleteInt(keccak256(abi.encodePacked(_key)));
    }

    function _deleteBytes32S(string memory _key) internal {
        _decashStorage.deleteBytes32(keccak256(abi.encodePacked(_key)));
    }
}

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
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable {
        _fallback();
    }

    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
                // delegatecall returns 0 on error.
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
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
    function _fallback() internal {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

/// @title DeCash Proxy Contract
/// @author Fabrizio Amodio (ZioFabry)

contract DeCashProxy is DeCashBase, Proxy {
    bytes32 private constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    event ProxyInitiated(address indexed implementation);
    event ProxyUpgraded(address indexed implementation);

    // Construct
    constructor(address _decashStorageAddress)
        DeCashBase(_decashStorageAddress)
    {
        assert(
            _IMPLEMENTATION_SLOT ==
                bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)
        );
        version = 1;
    }

    function upgrade(address _address)
        public
        onlyLatestContract("upgrade", msg.sender)
    {
        _setImplementation(_address);

        emit ProxyUpgraded(_address);
    }

    function initialize(address _address) external onlyOwner {
        require(
            !_getBool(keccak256(abi.encodePacked("proxy.init", address(this)))),
            "Proxy already initialized"
        );

        _setImplementation(_address);
        _setBool(keccak256(abi.encodePacked("proxy.init", address(this))), true);

        emit ProxyInitiated(_address);
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address _address) private {
        require(Address.isContract(_address), "address is not a contract");

        bytes32 slot = _IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _address)
        }
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view override returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }
}

contract GBPDProxy is DeCashProxy {
    constructor(address _storage) DeCashProxy(_storage) {}
}