/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

pragma solidity ^0.7.6;

// SPDX-License-Identifier: MIT
// Source code: https://github.com/DeCash-Official/smart-contracts

interface ERC20 {
    function balanceOf(address _owner) external view returns (uint256);

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool);

    function transferMany(address[] calldata _tos, uint256[] calldata _values)
        external
        returns (bool);

    function approve(address _spender, uint256 _value) external returns (bool);

    function mint(address _to, uint256 _value) external returns (bool);

    function burn(uint256 _value) external returns (bool);

    function burnFrom(address _from, uint256 _value) external returns (bool);
}

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Signature {
    enum Std {typed, personal, stringHex}

    enum Dest {transfer, transferFrom, transferMany, approve, approveAndCall}

    bytes public constant ETH_SIGNED_MESSAGE_PREFIX =
        "\x19Ethereum Signed Message:\n";

    // `transferViaSignature`: keccak256(abi.encodePacked(address(this), from, to, value, fee, deadline, sigId))
    bytes32 public constant DEST_TRANSFER =
        keccak256(
            abi.encodePacked(
                "address Contract",
                "address Sender",
                "address Recipient",
                "uint256 Amount (last 2 digits are decimals)",
                "uint256 Fee Amount (last 2 digits are decimals)",
                "address Fee Address",
                "uint256 Expiration",
                "uint256 Signature ID"
            )
        );

    // `transferManyViaSignature`: keccak256(abi.encodePacked(address(this), from, to/value array, deadline, sigId))
    bytes32 public constant DEST_TRANSFER_MANY =
        keccak256(
            abi.encodePacked(
                "address Contract",
                "address Sender",
                "bytes32 Recipient/Amount Array hash",
                "uint256 Fee Amount (last 2 digits are decimals)",
                "address Fee Address",
                "uint256 Expiration",
                "uint256 Signature ID"
            )
        );

    // `transferFromViaSignature`: keccak256(abi.encodePacked(address(this), signer, from, to, value, fee, deadline, sigId))
    bytes32 public constant DEST_TRANSFER_FROM =
        keccak256(
            abi.encodePacked(
                "address Contract",
                "address Approved",
                "address From",
                "address Recipient",
                "uint256 Amount (last 2 digits are decimals)",
                "uint256 Fee Amount (last 2 digits are decimals)",
                "address Fee Address",
                "uint256 Expiration",
                "uint256 Signature ID"
            )
        );

    // `approveViaSignature`: keccak256(abi.encodePacked(address(this), from, spender, value, fee, deadline, sigId))
    bytes32 public constant DEST_APPROVE =
        keccak256(
            abi.encodePacked(
                "address Contract",
                "address Approval",
                "address Recipient",
                "uint256 Amount (last 2 digits are decimals)",
                "uint256 Fee Amount (last 2 digits are decimals)",
                "address Fee Address",
                "uint256 Expiration",
                "uint256 Signature ID"
            )
        );

    // `approveAndCallViaSignature`: keccak256(abi.encodePacked(address(this), from, spender, value, extraData, fee, deadline, sigId))
    bytes32 public constant DEST_APPROVE_AND_CALL =
        keccak256(
            abi.encodePacked(
                "address Contract",
                "address Approval",
                "address Recipient",
                "uint256 Amount (last 2 digits are decimals)",
                "bytes Data to Transfer",
                "uint256 Fee Amount (last 2 digits are decimals)",
                "address Fee Address",
                "uint256 Expiration",
                "uint256 Signature ID"
            )
        );

    /**
     * Utility costly function to encode bytes HEX representation as string.
     *
     * @param sig - signature as bytes32 to represent as string
     */
    function hexToString(bytes32 sig) internal pure returns (bytes memory) {
        bytes memory str = new bytes(64);

        for (uint8 i = 0; i < 32; ++i) {
            str[2 * i] = bytes1(
                (uint8(sig[i]) / 16 < 10 ? 48 : 87) + uint8(sig[i]) / 16
            );
            str[2 * i + 1] = bytes1(
                (uint8(sig[i]) % 16 < 10 ? 48 : 87) + (uint8(sig[i]) % 16)
            );
        }

        return str;
    }

    /**
     * Internal method that makes sure that the given signature corresponds to a given data and is made by `signer`.
     * It utilizes three (four) standards of message signing in Ethereum, as at the moment of this smart contract
     * development there is no single signing standard defined. For example, Metamask and Geth both support
     * personal_sign standard, SignTypedData is only supported by Matamask, Trezor does not support "widely adopted"
     * Ethereum personal_sign but rather personal_sign with fixed prefix and so on.
     * Note that it is always possible to forge any of these signatures using the private key, the problem is that
     * third-party wallets must adopt a single standard for signing messages.
     *
     * @param _data      - original data which had to be signed by `signer`
     * @param _signer    - account which made a signature
     * @param _sig       - signature made by `from`, which is the proof of `from`'s agreement with the above parameters
     * @param _sigStd    - chosen standard for signature validation. The signer must explicitly tell which standard they use
     * @param _sigDest   - for which type of action this signature was made for
     */
    function requireSignature(
        bytes32 _data,
        address _signer,
        bytes memory _sig,
        Std _sigStd,
        Dest _sigDest
    ) internal {
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // solium-disable-line security/no-inline-assembly
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            v := byte(0, mload(add(_sig, 96)))
        }

        if (v < 27) v += 27;

        if (_sigStd == Std.typed) {
            bytes32 dest;

            if (_sigDest == Dest.transfer) {
                dest = DEST_TRANSFER;
            } else if (_sigDest == Dest.transferMany) {
                dest = DEST_TRANSFER_MANY;
            } else if (_sigDest == Dest.transferFrom) {
                dest = DEST_TRANSFER_FROM;
            } else if (_sigDest == Dest.approve) {
                dest = DEST_APPROVE;
            } else if (_sigDest == Dest.approveAndCall) {
                dest = DEST_APPROVE_AND_CALL;
            }

            // Typed signature. This is the most likely scenario to be used and accepted
            require(
                _signer ==
                    ecrecover(
                        keccak256(abi.encodePacked(dest, _data)),
                        v,
                        r,
                        s
                    ),
                "Invalid typed signature"
            );
        } else if (_sigStd == Std.personal) {
            // Ethereum signed message signature (Geth and Trezor)
            require(
                _signer ==
                    ecrecover(
                        keccak256(
                            abi.encodePacked(
                                ETH_SIGNED_MESSAGE_PREFIX,
                                "32",
                                _data
                            )
                        ),
                        v,
                        r,
                        s
                    ) || // Geth-adopted
                    _signer ==
                    ecrecover(
                        keccak256(
                            abi.encodePacked(
                                ETH_SIGNED_MESSAGE_PREFIX,
                                "\x20",
                                _data
                            )
                        ),
                        v,
                        r,
                        s
                    ), // Trezor-adopted
                "Invalid personal signature"
            );
        } else {
            // == 2; Signed string hash signature (the most expensive but universal)
            require(
                _signer ==
                    ecrecover(
                        keccak256(
                            abi.encodePacked(
                                ETH_SIGNED_MESSAGE_PREFIX,
                                "64",
                                hexToString(_data)
                            )
                        ),
                        v,
                        r,
                        s
                    ) || // Geth
                    _signer ==
                    ecrecover(
                        keccak256(
                            abi.encodePacked(
                                ETH_SIGNED_MESSAGE_PREFIX,
                                "\x40",
                                hexToString(_data)
                            )
                        ),
                        v,
                        r,
                        s
                    ), // Trezor
                "Invalid stringHex signature"
            );
        }
    }

    /**
     * This function return the signature of the array of recipient/value pair
     *
     * @param _tos[]         - array of account recipients
     * @param _values[]      - array of amount
     */
    function calculateManySig(address[] memory _tos, uint256[] memory _values)
        internal
        pure
        returns (bytes32)
    {
        bytes32 tv = keccak256(abi.encodePacked(_tos[0], _values[0]));

        uint256 ln = _tos.length;

        for (uint8 x = 1; x < ln; x++) {
            tv = keccak256(abi.encodePacked(tv, _tos[x], _values[x]));
        }

        return tv;
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

/// @title DeCash Token Multisignature Management
/// @author Fabrizio Amodio (ZioFabry)

abstract contract DeCashMultisignature {
    bytes32[] public allOperations;
    mapping(bytes32 => uint256) public allOperationsIndicies;
    mapping(bytes32 => uint256) public votesCountByOperation;
    mapping(bytes32 => address) public firstByOperation;
    mapping(bytes32 => mapping(address => uint8)) public votesOwnerByOperation;
    mapping(bytes32 => address[]) public votesIndicesByOperation;

    uint256 public signerGeneration;
    address internal _insideCallSender;
    uint256 internal _insideCallCount;

    event RequiredSignerChanged(
        uint256 newRequiredSignature,
        uint256 generation
    );
    event OperationCreated(bytes32 operation, address proposer);
    event OperationUpvoted(bytes32 operation, address voter);
    event OperationPerformed(bytes32 operation, address performer);
    event OperationCancelled(bytes32 operation, address performer);

    /**
     * @dev Allows to perform method only after many owners call it with the same arguments
     * @param _howMany defines how mant signature are required
     * @param _generation multiusignature generation
     */
    modifier onlyMultiSignature(uint256 _howMany, uint256 _generation) {
        if (_checkMultiSignature(_howMany, _generation)) {
            bool update = (_insideCallSender == address(0));
            if (update) {
                _insideCallSender = msg.sender;
                _insideCallCount = _howMany;
            }

            _;

            if (update) {
                _insideCallSender = address(0);
                _insideCallCount = 0;
            }
        }
    }

    /**
     * @dev Allows owners to change their mind by cacnelling votesMaskByOperation operations
     * @param operation defines which operation to delete
     */
    function cancelOperation(bytes32 operation) external {
        require(votesCountByOperation[operation] > 0, "Operation not found");

        _deleteOperation(operation);

        emit OperationCancelled(operation, msg.sender);
    }

    /**
     * @dev onlyManyOwners modifier helper
     * @param _howMany defines how mant signature are required
     * @param _generation multiusignature generation
     */
    function _checkMultiSignature(uint256 _howMany, uint256 _generation)
        internal
        returns (bool)
    {
        if (_howMany < 2) return true;

        if (_insideCallSender == msg.sender) {
            require(_howMany <= _insideCallCount, "howMany > _insideCallCount");
            return true;
        }

        bytes32 operation = keccak256(abi.encodePacked(msg.data, _generation));

        uint256 operationVotesCount = votesCountByOperation[operation] + 1;
        votesCountByOperation[operation] = operationVotesCount;

        if (firstByOperation[operation] == address(0)) {
            firstByOperation[operation] = msg.sender;

            allOperationsIndicies[operation] = allOperations.length;
            allOperations.push(operation);

            emit OperationCreated(operation, msg.sender);
        } else {
            require(
                votesOwnerByOperation[operation][msg.sender] == 0,
                "[operation][msg.sender] != 0"
            );
        }

        votesIndicesByOperation[operation].push(msg.sender);
        votesOwnerByOperation[operation][msg.sender] = 1;

        emit OperationUpvoted(operation, msg.sender);

        if (operationVotesCount < _howMany) return false;

        _deleteOperation(operation);

        emit OperationPerformed(operation, msg.sender);

        return true;
    }

    /**
     * @dev Used to delete cancelled or performed operation
     * @param operation defines which operation to delete
     */
    function _deleteOperation(bytes32 operation) internal {
        uint256 index = allOperationsIndicies[operation];
        if (index < allOperations.length - 1) {
            // Not last
            allOperations[index] = allOperations[allOperations.length - 1];
            allOperationsIndicies[allOperations[index]] = index;
        }

        delete allOperations[allOperations.length - 1];
        delete allOperationsIndicies[operation];
        delete votesCountByOperation[operation];
        delete firstByOperation[operation];

        uint8 x;
        uint256 ln = votesIndicesByOperation[operation].length;

        for (x = 0; x < ln; x++) {
            delete votesOwnerByOperation[operation][
                votesIndicesByOperation[operation][x]
            ];
        }

        for (x = 0; x < ln; x++) {
            votesIndicesByOperation[operation].pop();
        }
    }
}

/// @title DeCash Token implementation based on the DeCash perpetual storage
/// @author Fabrizio Amodio (ZioFabry)

contract DeCashToken is DeCashBase, DeCashMultisignature, ERC20 {
    using SafeMath for uint256;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    modifier onlyLastest {
        require(
            address(this) ==
                _getAddress(
                    keccak256(abi.encodePacked("contract.address", "token"))
                ) ||
                address(this) ==
                _getAddress(
                    keccak256(abi.encodePacked("contract.address", "proxy"))
                ),
            "Invalid or outdated contract"
        );
        _;
    }

    modifier whenNotPaused {
        require(!isPaused(), "Contract is paused");
        _;
    }
    modifier whenPaused {
        require(isPaused(), "Contract is not paused");
        _;
    }

    event Paused(address indexed from);
    event Unpaused(address indexed from);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    // Construct
    constructor(address _decashStorageAddress)
        DeCashBase(_decashStorageAddress)
    {
        version = 1;
    }

    function initialize(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint8 _tokenDecimals
    ) public onlyOwner {
        uint256 currentVersion =
            _getUint(keccak256(abi.encodePacked("token.version", _tokenName)));

        if (currentVersion == 0) {
            _name = _tokenName;
            _symbol = _tokenSymbol;
            _decimals = _tokenDecimals;

            _setString(keccak256(abi.encodePacked("token.name", _name)), _name);
            _setString(
                keccak256(abi.encodePacked("token.symbol", _name)),
                _symbol
            );
            _setUint(
                keccak256(abi.encodePacked("token.decimals", _name)),
                _decimals
            );
            _setBool(
                keccak256(abi.encodePacked("contract.paused", _name)),
                false
            );
            _setUint(keccak256(abi.encodePacked("mint.reqSign", _name)), 1);
        }

        if (currentVersion != version) {
            _setUint(
                keccak256(abi.encodePacked("token.version", _name)),
                version
            );
        }
    }

    function isPaused() public view returns (bool) {
        return _getBool(keccak256(abi.encodePacked("contract.paused", _name)));
    }

    /**
     * @dev Allows owners to change number of required signature for multiSignature Operations
     * @param _reqsign defines how many signature is required
     */
    function changeRequiredSigners(uint256 _reqsign)
        external
        onlySuperUser
        onlyLastest
        returns (uint256)
    {
        _setReqSign(_reqsign);

        uint256 _generation = _getSignGeneration() + 1;
        _setSignGeneration(_generation);

        emit RequiredSignerChanged(_reqsign, _generation);

        return _generation;
    }

    // ERC20 Implementation
    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view returns (uint256) {
        return _getTotalSupply();
    }

    function pause() external onlySuperUser onlyLastest whenNotPaused {
        _setBool(keccak256(abi.encodePacked("contract.paused", _name)), true);
        emit Paused(msg.sender);
    }

    function unpause() external onlySuperUser onlyLastest whenPaused {
        _setBool(keccak256(abi.encodePacked("contract.paused", _name)), false);
        emit Unpaused(msg.sender);
    }

    function balanceOf(address _owner)
        external
        view
        override
        returns (uint256)
    {
        return _getBalance(_owner);
    }

    function allowance(address _owner, address _spender)
        external
        view
        override
        returns (uint256)
    {
        return _getAllowed(_owner, _spender);
    }

    function transfer(address _to, uint256 _value)
        external
        override
        onlyLastest
        whenNotPaused
        returns (bool)
    {
        return _transfer(msg.sender, _to, _value);
    }

    function transferMany(address[] calldata _tos, uint256[] calldata _values)
        external
        override
        onlyLastest
        whenNotPaused
        returns (bool)
    {
        return _transferMany(msg.sender, _tos, _values);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external override onlyLastest whenNotPaused returns (bool) {
        return _transferFrom(msg.sender, _from, _to, _value);
    }

    function approve(address _spender, uint256 _value)
        external
        override
        onlyLastest
        whenNotPaused
        returns (bool)
    {
        return _approve(msg.sender, _spender, _value);
    }

    function burn(uint256 _value)
        external
        override
        onlyLastest
        whenNotPaused
        returns (bool)
    {
        return _burn(msg.sender, _value);
    }

    function burnFrom(address _from, uint256 _value)
        external
        override
        onlyLastest
        whenNotPaused
        returns (bool)
    {
        _approve(_from, msg.sender, _getAllowed(_from, msg.sender).sub(_value));

        return _burn(_from, _value);
    }

    function mint(address _to, uint256 _value)
        external
        override
        onlySuperUser
        onlyLastest
        whenNotPaused
        onlyMultiSignature(_getReqSign(), _getSignGeneration())
        returns (bool success)
    {
        _addBalance(_to, _value);
        _addTotalSupply(_value);

        emit Transfer(address(0), _to, _value);

        return true;
    }

    /**
     * This function distincts transaction signer from transaction executor. It allows anyone to transfer tokens
     * from the `from` account by providing a valid signature, which can only be obtained from the `from` account owner.
     * Note that passed parameter sigId is unique and cannot be passed twice (prevents replay attacks). When there's
     * a need to make signature once again (because the first on is lost or whatever), user should sign the message
     * with the same sigId, thus ensuring that the previous signature won't be used if the new one passes.
     * Use case: the user wants to send some tokens to other user or smart contract, but don't have ether to do so.
     *
     * @param _from          - the account giving its signature to transfer `value` tokens to `to` address
     * @param _to            - the account receiving `value` tokens
     * @param _value         - the value in tokens to transfer
     * @param _fee           - a fee to pay to `feeRecipient`
     * @param _feeRecipient  - account which will receive fee
     * @param _deadline      - until when the signature is valid
     * @param _sigId         - signature unique ID. Signatures made with the same signature ID cannot be submitted twice
     * @param _sig           - signature made by `from`, which is the proof of `from`'s agreement with the above parameters
     * @param _sigStd        - chosen standard for signature validation. The signer must explicitly tell which standard they use
     */
    function transferViaSignature(
        address _from,
        address _to,
        uint256 _value,
        uint256 _fee,
        address _feeRecipient,
        uint256 _deadline,
        uint256 _sigId,
        bytes calldata _sig,
        Signature.Std _sigStd
    ) external onlyLastest {
        _validateViaSignatureParams(
            msg.sender,
            _from,
            _feeRecipient,
            _deadline,
            _sigId
        );

        Signature.requireSignature(
            keccak256(
                abi.encodePacked(
                    address(this),
                    _from,
                    _to,
                    _value,
                    _fee,
                    _feeRecipient,
                    _deadline,
                    _sigId
                )
            ),
            _from,
            _sig,
            _sigStd,
            Signature.Dest.transfer
        );

        _subBalance(_from, _value.add(_fee)); // Subtract (value + fee)
        _addBalance(_to, _value);
        emit Transfer(_from, _to, _value);

        if (_fee > 0) {
            _addBalance(_feeRecipient, _fee);
            emit Transfer(_from, _feeRecipient, _fee);
        }

        _burnSigId(_from, _sigId);
    }

    /**
     * This function distincts transaction signer from transaction executor. It allows anyone to transfer tokens
     * from the `from` account to multiple recipient address by providing a valid signature, which can only be obtained from the `from` account owner.
     * Note that passed parameter sigId is unique and cannot be passed twice (prevents replay attacks). When there's
     * a need to make signature once again (because the first on is lost or whatever), user should sign the message
     * with the same sigId, thus ensuring that the previous signature won't be used if the new one passes.
     * Also note that the 1st recipient must be a valid fee receiver
     * Use case: the user wants to send some tokens to multiple users or smart contracts, but don't have ether to do so.
     *
     * @param _from          - the account giving its signature to transfer `value` tokens to `to` address
     * @param _tos[]         - array of account recipients
     * @param _values[]      - array of amount
     * @param _fee           - a fee to pay to `feeRecipient`
     * @param _feeRecipient  - account which will receive fee
     * @param _deadline      - until when the signature is valid
     * @param _sigId         - signature unique ID. Signatures made with the same signature ID cannot be submitted twice
     * @param _sig           - signature made by `from`, which is the proof of `from`'s agreement with the above parameters
     * @param _sigStd        - chosen standard for signature validation. The signer must explicitly tell which standard they use
     */
    function transferManyViaSignature(
        address _from,
        address[] calldata _tos,
        uint256[] calldata _values,
        uint256 _fee,
        address _feeRecipient,
        uint256 _deadline,
        uint256 _sigId,
        bytes calldata _sig,
        Signature.Std _sigStd
    ) external onlyLastest {
        uint256 tosLen = _tos.length;

        require(tosLen == _values.length, "Wrong array parameters");
        require(tosLen <= 100, "Too many receiver");

        _validateViaSignatureParams(
            msg.sender,
            _from,
            _feeRecipient,
            _deadline,
            _sigId
        );

        bytes32 multisig = Signature.calculateManySig(_tos, _values);

        Signature.requireSignature(
            keccak256(
                abi.encodePacked(
                    address(this),
                    _from,
                    multisig,
                    _fee,
                    _feeRecipient,
                    _deadline,
                    _sigId
                )
            ),
            _from,
            _sig,
            _sigStd,
            Signature.Dest.transferMany
        );

        _subBalance(_from, _calculateTotal(_values).add(_fee));

        for (uint8 x = 0; x < tosLen; x++) {
            _addBalance(_tos[x], _values[x]);
            emit Transfer(_from, _tos[x], _values[x]);
        }

        if (_fee > 0) {
            _addBalance(_feeRecipient, _fee);
            emit Transfer(_from, _feeRecipient, _fee);
        }

        _burnSigId(_from, _sigId);
    }

    /**
     * Same as `transferViaSignature`, but for `approve`.
     * Use case: the user wants to set an allowance for the smart contract or another user without having ether on their
     * balance.
     *
     * @param _from          - the account to approve withdrawal from, which signed all below parameters
     * @param _spender       - the account allowed to withdraw tokens from `from` address
     * @param _value         - the value in tokens to approve to withdraw
     * @param _fee           - a fee to pay to `feeRecipient`
     * @param _feeRecipient  - account which will receive fee
     * @param _deadline      - until when the signature is valid
     * @param _sigId         - signature unique ID. Signatures made with the same signature ID cannot be submitted twice
     * @param _sig           - signature made by `from`, which is the proof of `from`'s agreement with the above parameters
     * @param _sigStd        - chosen standard for signature validation. The signer must explicitely tell which standard they use
     */
    function approveViaSignature(
        address _from,
        address _spender,
        uint256 _value,
        uint256 _fee,
        address _feeRecipient,
        uint256 _deadline,
        uint256 _sigId,
        bytes calldata _sig,
        Signature.Std _sigStd
    ) external onlyLastest {
        _validateViaSignatureParams(
            msg.sender,
            _from,
            _feeRecipient,
            _deadline,
            _sigId
        );

        Signature.requireSignature(
            keccak256(
                abi.encodePacked(
                    address(this),
                    _from,
                    _spender,
                    _value,
                    _fee,
                    _feeRecipient,
                    _deadline,
                    _sigId
                )
            ),
            _from,
            _sig,
            _sigStd,
            Signature.Dest.approve
        );

        if (_fee > 0) {
            _subBalance(_from, _fee);
            _addBalance(_feeRecipient, _fee);
            emit Transfer(_from, _feeRecipient, _fee);
        }

        _setAllowed(_from, _spender, _value);
        emit Approval(_from, _spender, _value);

        _burnSigId(_from, _sigId);
    }

    /**
     * Same as `transferViaSignature`, but for `transferFrom`.
     * Use case: the user wants to withdraw tokens from a smart contract or another user who allowed the user to
     * do so. Important note: the fee is subtracted from the `value`, and `to` address receives `value - fee`.
     *
     * @param _signer       - the address allowed to call transferFrom, which signed all below parameters
     * @param _from         - the account to make withdrawal from
     * @param _to           - the address of the recipient
     * @param _value        - the value in tokens to withdraw
     * @param _fee          - a fee to pay to `feeRecipient`
     * @param _feeRecipient - account which will receive fee
     * @param _deadline     - until when the signature is valid
     * @param _sigId        - signature unique ID. Signatures made with the same signature ID cannot be submitted twice
     * @param _sig          - signature made by `from`, which is the proof of `from`'s agreement with the above parameters
     * @param _sigStd       - chosen standard for signature validation. The signer must explicitly tell which standard they use
     */
    function transferFromViaSignature(
        address _signer,
        address _from,
        address _to,
        uint256 _value,
        uint256 _fee,
        address _feeRecipient,
        uint256 _deadline,
        uint256 _sigId,
        bytes calldata _sig,
        Signature.Std _sigStd
    ) external onlyLastest {
        _validateViaSignatureParams(
            msg.sender,
            _from,
            _feeRecipient,
            _deadline,
            _sigId
        );

        Signature.requireSignature(
            keccak256(
                abi.encodePacked(
                    address(this),
                    _from,
                    _to,
                    _value,
                    _fee,
                    _feeRecipient,
                    _deadline,
                    _sigId
                )
            ),
            _signer,
            _sig,
            _sigStd,
            Signature.Dest.transferFrom
        );

        _subAllowed(_from, _signer, _value.add(_fee));

        _subBalance(_from, _value.add(_fee)); // Subtract (value + fee)
        _addBalance(_to, _value);
        emit Transfer(_from, _to, _value);

        if (_fee > 0) {
            _addBalance(_feeRecipient, _fee);
            emit Transfer(_from, _feeRecipient, _fee);
        }

        _burnSigId(_from, _sigId);
    }

    // Total Supply Handling
    function _getTotalSupply() internal view returns (uint256) {
        return
            _getUint(keccak256(abi.encodePacked("token.totalSupply", _name)));
    }

    function _setTotalSupply(uint256 _supply) internal {
        _setUint(
            keccak256(abi.encodePacked("token.totalSupply", _name)),
            _supply
        );
    }

    function _addTotalSupply(uint256 _supply) internal {
        _setTotalSupply(_getTotalSupply().add(_supply));
    }

    function _subTotalSupply(uint256 _supply) internal {
        _setTotalSupply(_getTotalSupply().sub(_supply));
    }

    // Allowed Handling
    function _getAllowed(address _owner, address _spender)
        internal
        view
        returns (uint256)
    {
        return
            _getUint(
                keccak256(
                    abi.encodePacked("token.allowed", _name, _owner, _spender)
                )
            );
    }

    function _setAllowed(
        address _owner,
        address _spender,
        uint256 _remaining
    ) internal {
        _setUint(
            keccak256(
                abi.encodePacked("token.allowed", _name, _owner, _spender)
            ),
            _remaining
        );
    }

    function _addAllowed(
        address _owner,
        address _spender,
        uint256 _balance
    ) internal {
        _setAllowed(
            _owner,
            _spender,
            _getAllowed(_owner, _spender).add(_balance)
        );
    }

    function _subAllowed(
        address _owner,
        address _spender,
        uint256 _balance
    ) internal {
        _setAllowed(
            _owner,
            _spender,
            _getAllowed(_owner, _spender).sub(_balance)
        );
    }

    // Balance Handling
    function _getBalance(address _owner) internal view returns (uint256) {
        return
            _getUint(
                keccak256(abi.encodePacked("token.balance", _name, _owner))
            );
    }

    function _setBalance(address _owner, uint256 _balance) internal {
        require(!_isBlacklisted(_owner), "Blacklisted");
        _setUint(
            keccak256(abi.encodePacked("token.balance", _name, _owner)),
            _balance
        );
    }

    function _addBalance(address _owner, uint256 _balance) internal {
        _setBalance(_owner, _getBalance(_owner).add(_balance));
    }

    function _subBalance(address _owner, uint256 _balance) internal {
        _setBalance(_owner, _getBalance(_owner).sub(_balance));
    }

    // Other Variable Handling
    function _getReqSign() internal view returns (uint256) {
        return _getUint(keccak256(abi.encodePacked("mint.reqSign", _name)));
    }

    function _getSignGeneration() internal view returns (uint256) {
        return _getUint(keccak256(abi.encodePacked("sign.generation", _name)));
    }

    function _getUsedSigIds(address _signer, uint256 _sigId)
        internal
        view
        returns (bool)
    {
        return
            _getBool(
                keccak256(
                    abi.encodePacked("sign.generation", _name, _signer, _sigId)
                )
            );
    }

    function _setReqSign(uint256 _reqsign) internal {
        _setUint(keccak256(abi.encodePacked("mint.reqSign", _name)), _reqsign);
    }

    function _setSignGeneration(uint256 _generation) internal {
        _setUint(
            keccak256(abi.encodePacked("sign.generation", _name)),
            _generation
        );
    }

    function _setUsedSigIds(
        address _signer,
        uint256 _sigId,
        bool _used
    ) internal {
        _setBool(
            keccak256(
                abi.encodePacked("sign.generation", _name, _signer, _sigId)
            ),
            _used
        );
    }

    function _burn(address _from, uint256 _value) internal returns (bool) {
        _subBalance(_from, _value);
        _subTotalSupply(_value);

        emit Transfer(_from, address(0), _value);

        return true;
    }

    function _transfer(
        address _sender,
        address _to,
        uint256 _value
    ) internal returns (bool) {
        _subBalance(_sender, _value);
        _addBalance(_to, _value);

        emit Transfer(_sender, _to, _value);

        return true;
    }

    function _transferMany(
        address _sender,
        address[] calldata _tos,
        uint256[] calldata _values
    ) internal returns (bool) {
        uint256 tosLen = _tos.length;

        require(tosLen == _values.length, "Wrong array parameter");
        require(tosLen <= 100, "Too many receiver");

        _subBalance(_sender, _calculateTotal(_values));

        for (uint8 x = 0; x < tosLen; x++) {
            _addBalance(_tos[x], _values[x]);

            emit Transfer(_sender, _tos[x], _values[x]);
        }

        return true;
    }

    function _transferFrom(
        address _sender,
        address _from,
        address _to,
        uint256 _value
    ) internal returns (bool) {
        _subAllowed(_from, _sender, _value);
        _subBalance(_from, _value);
        _addBalance(_to, _value);

        emit Transfer(_from, _to, _value);

        return true;
    }

    function _approve(
        address _sender,
        address _spender,
        uint256 _value
    ) internal returns (bool) {
        _setAllowed(_sender, _spender, _value);

        emit Approval(_sender, _spender, _value);

        return true;
    }

    function _calculateTotal(uint256[] memory _values)
        internal
        pure
        returns (uint256)
    {
        uint256 total = 0;
        uint256 ln = _values.length;

        for (uint8 x = 0; x < ln; x++) {
            total = total.add(_values[x]);
        }

        return total;
    }

    // Delegated functions

    /**
     * These functions are used to avoid the use of the modifiers that can cause the "stack too deep" error
     * also for code optimization
     */
    function _validateViaSignatureParams(
        address _delegator,
        address _from,
        address _feeRecipient,
        uint256 _deadline,
        uint256 _sigId
    ) internal view {
        require(!isPaused(), "Contract paused");
        require(_isDelegator(_delegator), "Sender is not a delegator");
        require(_isFeeRecipient(_feeRecipient), "Invalid fee recipient");
        require(block.timestamp <= _deadline, "Request expired");
        require(!_getUsedSigIds(_from, _sigId), "Request already used");
    }

    function _burnSigId(address _from, uint256 _sigId) internal {
        _setUsedSigIds(_from, _sigId, true);
    }
}

contract GBPDToken is DeCashToken {
    constructor(address _storage) DeCashToken(_storage) {}
}