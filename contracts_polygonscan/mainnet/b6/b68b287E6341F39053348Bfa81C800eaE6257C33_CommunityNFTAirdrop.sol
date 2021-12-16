/**
 *Submitted for verification at polygonscan.com on 2021-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

contract CommunityTokenManager is Ownable {
    address public tokenFactory;

    mapping(address => uint256) public numOfDeployedContracts;
    mapping(address => mapping(uint256 => address)) public contractsByDeployer;

    /// @param _tokenFactoryAddress The address of the NFT factory contract.
    function setTokenFactory(address _tokenFactoryAddress) external onlyOwner {
        tokenFactory = _tokenFactoryAddress;
    }

    /// @notice Creates the NFT contract with this contract as the owner.
    /// @param _tokenName Name of the NFT.
    /// @param _tokenSymbol Symbol of the NFT.
    function deployTokenContract(string calldata _tokenName, string calldata _tokenSymbol) public {
        address roleToken = ICommunityTokenFactory(tokenFactory).deployTokenContract(_tokenName, _tokenSymbol);
        contractsByDeployer[msg.sender][numOfDeployedContracts[msg.sender]] = roleToken;
        numOfDeployedContracts[msg.sender] += 1;
    }

    /// @notice Transfers ownership of the NFT contract.
    /// @dev Only the deployer of the contract can transfer ownership.
    /// @dev The intended functionality of the NFT can no longer be guaranteed.
    /// @param _to New owner of the NFT contract.
    /// @param _id Id of the NFT contract.
    function transferTokenOwnership(address _to, uint256 _id) external {
        address tokenAddress = contractsByDeployer[msg.sender][_id];
        require(tokenAddress != address(0), "Not valid id");

        IOwnable(tokenAddress).transferOwnership(_to);
    }
}

contract CommunityDropBase is CommunityTokenManager, Pausable {
    address internal bot;
    IDropCenter dropCenter;

    struct Drop {
        string dropName;
        string platform;
        string serverId;
        uint256 contractId;
    }

    event NewAirdrop(string indexed dropUrl, uint256 numOfRoles, address tokenAddress);
    event DropOnServer(string dropUrl, string channelId, address tokenAddress);
    event Claimed(string indexed platform, string indexed roleId, address indexed tokenContract, address user);
    event Granted(address indexed user, string platform, string roleId, address tokenContract);
    event RoleAdded(string indexed dropUrl, string roleId);
    event DropStopped(string indexed dropUrl, string roleId);
    event NewRoleOnServer(string dropUrl, string roleId, string channelId);

    /// @param _newBotAddress The address of the bot creating the signatures.
    function changeBot(address _newBotAddress) external onlyOwner {
        bot = _newBotAddress;
    }

    /// @notice stops the contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice restarts the contract
    function unpause() external onlyOwner {
        _unpause();
    }
}

interface ICommunityToken {
    function addRoleData(
        string calldata _community,
        string calldata _roleId,
        string calldata _metadataHash
    ) external;

    function safeMint(
        address _to,
        string calldata _platform,
        string calldata _roleId
    ) external;
}

interface ICommunityTokenFactory {
    function deployTokenContract(string calldata _tokenName, string calldata _tokenSymbol) external returns (address);
}

interface IDropCenter {
    function newDrop(string calldata _dropUrl) external;
}

interface IOwnable {
    function owner() external returns (address);

    function transferOwnership(address _newOwner) external;
}

contract CommunityNFTAirdrop is CommunityDropBase {
    using ECDSA for bytes32;

    mapping(string => Drop) public dropsByUrl;
    // User -> platform -> Role ID -> TokenAddress
    mapping(string => mapping(string => mapping(string => mapping(address => bool)))) public claims;
    mapping(address => mapping(string => mapping(string => mapping(address => bool)))) public approvals;
    // url -> Role ID -> TokenAddress
    mapping(string => mapping(string => mapping(address => bool))) public active;
    // platform -> Role ID -> TokenAddress
    mapping(string => mapping(string => mapping(address => string))) public metadata;

    /// @param _dropCenterAddress The address of the drop center contract.
    /// @param _botAddress The address of the bot wallet creating the signatures.
    constructor(address _dropCenterAddress, address _botAddress) {
        dropCenter = IDropCenter(_dropCenterAddress);
        bot = _botAddress;
    }

    /// @notice Creates a new airdrop for the given roles and a new NFT contract.
    /// @param _signature Signature created by the bot.
    /// @param _tokenName Name of the NFT.
    /// @param _tokenSymbol Symbol of the NFT.
    /// @param _dropUrl Url of the airdrop.
    /// @param _platform platform of the community.
    /// @param _dropName Name of the airdrop.
    /// @param _serverId Id of the server or group of the airdrop.
    /// @param _roleIds Ids of the roles in the server that can claim an NFT. ServerId if not defined.
    /// @param _metadataHashes Array of ipfs hashes for the metadata json files. One for each role.
    /// @param _channelId The Id of the channel where the bot announces the airdrop. ServerId if not defined.
    function startAirdrop(
        bytes memory _signature,
        string calldata _tokenName,
        string calldata _tokenSymbol,
        string memory _dropUrl,
        string memory _platform,
        string memory _dropName,
        string memory _serverId,
        string[] memory _roleIds,
        string[] memory _metadataHashes,
        string memory _channelId
    ) external whenNotPaused {
        // Check the signature
        bytes32 message = keccak256(
            abi.encode(address(this), _platform, _serverId, _dropUrl, _roleIds, _metadataHashes, msg.sender)
        ).toEthSignedMessageHash();
        require(_roleIds.length > 0, "No valid roles");
        require(_roleIds.length == _metadataHashes.length, "Roles and their data are not linked");
        require(message.recover(_signature) == bot, "Not valid signature");
        require(bytes(dropsByUrl[_dropUrl].dropName).length == 0, "Drop already exists");

        deployTokenContract(_tokenName, _tokenSymbol);
        uint256 contractId = numOfDeployedContracts[msg.sender] - 1;
        address roleToken = contractsByDeployer[msg.sender][contractId];

        for (uint256 i = 0; i < _roleIds.length; i++) {
            active[_dropUrl][_roleIds[i]][roleToken] = true;
            metadata[_platform][_roleIds[i]][roleToken] = _metadataHashes[i];

            ICommunityToken(roleToken).addRoleData(_platform, _roleIds[i], _metadataHashes[i]);
        }

        Drop memory drop;
        drop.dropName = _dropName;
        drop.platform = _platform;
        drop.serverId = _serverId;
        drop.contractId = contractId;

        dropCenter.newDrop(_dropUrl);
        dropsByUrl[_dropUrl] = drop;

        emit NewAirdrop(_dropUrl, _roleIds.length, roleToken);
        emit DropOnServer(_dropUrl, _channelId, roleToken);
    }

    /// @notice Creates a new airdrop for the given roles.
    /// @param _signature Signature created by the bot.
    /// @param _dropUrl Url of the airdrop.
    /// @param _platform platform of the community.
    /// @param _dropName Name of the airdrop.
    /// @param _serverId Id of the server or group of the airdrop.
    /// @param _roleIds Ids of the roles in the server that can claim an NFT. ServerId if not defined.
    /// @param _metadataHashes Array of ipfs hashes for the metadata json files. One for each role.
    /// @param _contractId Id of the NFT contract deployed by the caller.
    /// @param _channelId The Id of the channel where the bot announces the airdrop. ServerId if not defined.
    function startAirdropWithExistingToken(
        bytes memory _signature,
        string memory _dropUrl,
        string memory _platform,
        string memory _dropName,
        string memory _serverId,
        string[] memory _roleIds,
        string[] memory _metadataHashes,
        uint256 _contractId,
        string memory _channelId
    ) external whenNotPaused {
        // Check the signature
        bytes32 message = keccak256(
            abi.encode(address(this), _platform, _serverId, _dropUrl, _roleIds, _metadataHashes, msg.sender)
        ).toEthSignedMessageHash();
        require(_roleIds.length == _metadataHashes.length, "Roles and their data are not linked");
        require(message.recover(_signature) == bot, "Not valid signature");
        require(bytes(dropsByUrl[_dropUrl].dropName).length == 0, "Drop already exists");
        require(_contractId < numOfDeployedContracts[msg.sender], "Invalid NFT token");

        address roleToken = contractsByDeployer[msg.sender][_contractId];
        require(IOwnable(roleToken).owner() == address(this), "Token owner is not the contract");

        uint256 validRoles;

        for (uint256 i = 0; i < _roleIds.length; i++) {
            if ((bytes(metadata[_platform][_roleIds[i]][roleToken])).length == 0) {
                active[_dropUrl][_roleIds[i]][roleToken] = true;
                metadata[_platform][_roleIds[i]][roleToken] = _metadataHashes[i];

                ICommunityToken(roleToken).addRoleData(_platform, _roleIds[i], _metadataHashes[i]);
                validRoles++;
            }
        }
        require(validRoles > 0, "No valid roles");

        Drop memory drop;
        drop.dropName = _dropName;
        drop.platform = _platform;
        drop.serverId = _serverId;
        drop.contractId = _contractId;

        dropCenter.newDrop(_dropUrl);
        dropsByUrl[_dropUrl] = drop;

        emit NewAirdrop(_dropUrl, validRoles, roleToken);
        emit DropOnServer(_dropUrl, _channelId, roleToken);
    }

    /// @notice Stops the active airdrop for the given role.
    /// @dev If an airdrop is stopped it CAN NOT BE RESTARTED for that role.
    /// @param _signature Signature created by the bot.
    /// @param _dropUrl Url of the Drop.
    /// @param _roleId The id of a role or a server if roles are not defined.
    function stopAirdrop(
        bytes memory _signature,
        string memory _dropUrl,
        string memory _roleId
    ) external {
        Drop storage drop = dropsByUrl[_dropUrl];
        string memory platform = drop.platform;
        address roleToken = contractsByDeployer[msg.sender][drop.contractId];
        require(active[_dropUrl][_roleId][roleToken], "No active airdrop");

        // Check the signature
        bytes32 message = keccak256(abi.encode(address(this), platform, _roleId, roleToken, msg.sender, "stop"))
            .toEthSignedMessageHash();
        require(message.recover(_signature) == bot, "Not valid signature");

        active[_dropUrl][_roleId][roleToken] = false;

        emit DropStopped(_dropUrl, _roleId);
    }

    /// @notice Mints an NFT linked to the given role and transfers it to the user.
    /// @param _signature Signature created by the bot.
    /// @param _dropUrl Url of the Drop.
    /// @param _roleId The id of a role or a server if roles are not defined.
    /// @param _userId Hash of the user Id on the given platform.
    /// @param _tokenAddress Address of the NFT contract.
    function claim(
        bytes memory _signature,
        string memory _dropUrl,
        string memory _roleId,
        string memory _userId,
        address _tokenAddress
    ) external whenNotPaused {
        string memory platform = dropsByUrl[_dropUrl].platform;
        require(
            active[_dropUrl][_roleId][_tokenAddress] || approvals[msg.sender][platform][_roleId][_tokenAddress],
            "No active airdrop"
        );
        require(!claims[_userId][platform][_roleId][_tokenAddress], "Already claimed");
        require(IOwnable(_tokenAddress).owner() == address(this), "Token owner is not the contract");

        // Check the signature
        bytes32 message = keccak256(abi.encode(address(this), platform, _roleId, _tokenAddress, _userId, msg.sender))
            .toEthSignedMessageHash();
        require(message.recover(_signature) == bot, "Not valid signature");

        claims[_userId][platform][_roleId][_tokenAddress] = true;

        // Mint the NFT from the data and send it to the msg.sender
        ICommunityToken(_tokenAddress).safeMint(msg.sender, platform, _roleId);
        emit Claimed(platform, _roleId, _tokenAddress, msg.sender);
    }

    /// @notice Grants permission to an address to claim an NFT.
    /// @dev This function can be used to distribute NFTs after the arirdrop is stopped.
    /// @param _signature Signature created by the bot.
    /// @param _platform platform of the community.
    /// @param _roleId The id of a role or a server if roles are not defined.
    /// @param _user Address that can claim the NFT.
    /// @param _contractId Id of the token contract deployed by the server owner.
    function grant(
        bytes memory _signature,
        string memory _platform,
        string memory _roleId,
        address _user,
        uint256 _contractId
    ) external whenNotPaused {
        require(_contractId < numOfDeployedContracts[msg.sender], "Invalid NFT token");
        address roleToken = contractsByDeployer[msg.sender][_contractId];
        require(IOwnable(roleToken).owner() == address(this), "Token owner is not the contract");

        // Check the signature
        bytes32 message = keccak256(abi.encode(address(this), _platform, _roleId, _user, roleToken, msg.sender))
            .toEthSignedMessageHash();
        require(message.recover(_signature) == bot, "Not valid signature");
        require((bytes(metadata[_platform][_roleId][roleToken])).length > 0, "No Token for this role");

        approvals[_user][_platform][_roleId][roleToken] = true;

        emit Granted(_user, _platform, _roleId, roleToken);
    }

    /// @notice Adds a new role to a given drop.
    /// @dev Only the server owner can add a new role.
    /// @param _signature Signature created by the bot.
    /// @param _dropUrl Url of the airdrop.
    /// @param _roleId The id of a role or a server if roles are not defined.
    /// @param _channelId The Id of the channel where the bot announces the airdrop. ServerId if not defined.
    function addRoleToDrop(
        bytes memory _signature,
        string calldata _dropUrl,
        string calldata _roleId,
        string calldata _metadataHash,
        string calldata _channelId
    ) external whenNotPaused {
        // Check the signature
        bytes32 message = keccak256(abi.encode(address(this), _dropUrl, _roleId, _metadataHash, msg.sender))
            .toEthSignedMessageHash();
        require(message.recover(_signature) == bot, "Not valid signature");

        string memory platform = dropsByUrl[_dropUrl].platform;
        address roleToken = contractsByDeployer[msg.sender][dropsByUrl[_dropUrl].contractId];
        require((bytes(metadata[platform][_roleId][roleToken])).length == 0, "Role already dropped");
        require(bytes(dropsByUrl[_dropUrl].dropName).length > 0, "Drop does not exist");
        require(IOwnable(roleToken).owner() == address(this), "Token owner is not the contract");

        active[_dropUrl][_roleId][roleToken] = true;
        metadata[platform][_roleId][roleToken] = _metadataHash;

        ICommunityToken(roleToken).addRoleData(platform, _roleId, _metadataHash);

        emit NewRoleOnServer(_dropUrl, _roleId, _channelId);
        emit RoleAdded(_dropUrl, _roleId);
    }
}