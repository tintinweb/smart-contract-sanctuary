// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IDCRoleToken.sol";
import "./interfaces/IDCRoleTokenFactory.sol";

contract NFTAirdrop is Ownable, Pausable {
    using ECDSA for bytes32;

    address internal bot;
    address public tokenFactory;
    string public externalUrl;
    uint256 public numOfDrops;

    mapping(uint256 => string) public dropnamesById;
    mapping(string => Drop) private dropsByName;
    // User address -> Server ID -> DC Role ID -> TokenAddress
    mapping(address => mapping(string => mapping(string => mapping(address => Claim)))) public claims;
    // Server ID -> DC Role ID -> TokenAddress
    mapping(string => mapping(string => mapping(address => Claimable))) public claimables;
    mapping(address => uint256) public numOfDeployedContracts;
    mapping(address => mapping(uint256 => address)) public contractsByDeployer;

    struct Role {
        string roleId;
        string tokenImageHash;
        string NFTName;
        string[] traitTypes;
        string[] values;
    }

    struct Claimable {
        bool active;
        bool dropped;
    }

    struct Drop {
        string serverId;
        string[] roleIds;
        address tokenAddress;
    }

    struct Claim {
        bool claimed;
        bool approved;
    }

    event NewAirdrop(string dropname, string channelId);
    event DropOnServer(string indexed serverId, uint256 dropId);
    event Claimed(string indexed serverId, string indexed roleId, address indexed tokenContract, address user);
    event Granted(address indexed user, string serverId, string roleId, address tokenContract);

    /// @param _botAddress The address of the bot creating the signatures.
    constructor(address _botAddress, string memory _externalUrl) {
        bot = _botAddress;
        externalUrl = _externalUrl;
    }

    /// @param _newBotAddress The address of the bot creating the signatures.
    function changeBot(address _newBotAddress) external onlyOwner {
        bot = _newBotAddress;
    }

    /// @param _tokenFactoryAddress The address of the NFT factory contract.
    function setTokenFactory(address _tokenFactoryAddress) external onlyOwner {
        tokenFactory = _tokenFactoryAddress;
    }

    function setExternalUrl(string calldata _newUrl) external onlyOwner {
        externalUrl = _newUrl;
    }

    /// @notice Creates the NFT contract with this contract as the owner.
    /// @param _tokenName Name of the NFT.
    /// @param _tokenSymbol Symbol of the NFT.
    function deployTokenContract(string calldata _tokenName, string calldata _tokenSymbol) external {
        address roleToken = IDCRoleTokenFactory(tokenFactory).deployTokenContract(
            _tokenName,
            _tokenSymbol,
            externalUrl
        );
        contractsByDeployer[msg.sender][numOfDeployedContracts[msg.sender]] = roleToken;
        numOfDeployedContracts[msg.sender] += 1;
    }

    /// @notice Creates a new airdrop for the given roles.
    /// @param _signature Signature created by the bot.
    /// @param _dropName Name of the airdrop.
    /// @param _serverId Id of the Discord server.
    /// @param _roles An array of structs containing information about a role.
    /// @param _contractId Id of the token contract deployed by the server owner.
    /// @param _channelId The Id of the channel where the bot announces the airdrop.
    function newAirdrop(
        bytes memory _signature,
        string memory _dropName,
        string memory _serverId,
        Role[] memory _roles,
        uint256 _contractId,
        string memory _channelId
    ) external whenNotPaused {
        // Check the signature
        bytes32 message = keccak256(abi.encode(address(this), _serverId, _dropName, msg.sender))
            .toEthSignedMessageHash();
        require(message.recover(_signature) == bot, "Not valid signature");
        require(bytes(dropsByName[_dropName].serverId).length == 0, "Drop already exists");
        require(_contractId < numOfDeployedContracts[msg.sender], "Invalid NFT token");
        address roleToken = contractsByDeployer[msg.sender][_contractId];
        string[] memory roleIds = new string[](_roles.length);
        Drop memory drop;
        uint256 j;

        for (uint256 i = 0; i < _roles.length; i++) {
            if (!claimables[_serverId][_roles[i].roleId][roleToken].dropped) {
                roleIds[j] = _roles[i].roleId;

                claimables[_serverId][_roles[i].roleId][roleToken].dropped = true;
                claimables[_serverId][_roles[i].roleId][roleToken].active = true;

                IDCRoleToken(roleToken).addRoleData(
                    _serverId,
                    _roles[i].roleId,
                    _roles[i].tokenImageHash,
                    _roles[i].NFTName,
                    _roles[i].traitTypes,
                    _roles[i].values
                );
                j++;
            }
        }

        drop.serverId = _serverId;
        drop.tokenAddress = roleToken;
        drop.roleIds = roleIds;

        require(bytes(drop.roleIds[0]).length > 0, "No valid roles");
        dropnamesById[numOfDrops] = _dropName;
        dropsByName[_dropName] = drop;

        emit NewAirdrop(_dropName, _channelId);
        emit DropOnServer(_serverId, numOfDrops);

        numOfDrops += 1;
    }

    /// @notice Stops the active airdrop for the given roles.
    /// @dev If an airdrop is stopped it CAN NOT BE RESTARTED for that role.
    /// @param _signature Signature created by the bot.
    /// @param _serverId Id of the Discord server.
    /// @param _roleId The id of a Discord role.
    function stopAirdrop(
        bytes calldata _signature,
        string calldata _serverId,
        string calldata _roleId,
        uint256 _contractId
    ) external {
        require(_contractId < numOfDeployedContracts[msg.sender], "Invalid NFT token");
        address roleToken = contractsByDeployer[msg.sender][_contractId];

        // Check the signature
        bytes32 message = keccak256(abi.encode(address(this), _serverId, _roleId, roleToken, msg.sender, "stop"))
            .toEthSignedMessageHash();
        require(message.recover(_signature) == bot, "Not valid signature");

        claimables[_serverId][_roleId][roleToken].active = false;
    }

    /// @notice Mints an NFT for the user linked to the given role.
    /// @param _signature Signature created by the bot.
    /// @param _serverId Id of the Discord server.
    /// @param _roleId Discord role Id.
    /// @param _tokenAddress Address of the NFT contract.
    function claim(
        bytes calldata _signature,
        string calldata _serverId,
        string calldata _roleId,
        address _tokenAddress
    ) external whenNotPaused {
        Claim storage userClaim = claims[msg.sender][_serverId][_roleId][_tokenAddress];
        require(claimables[_serverId][_roleId][_tokenAddress].active || userClaim.approved, "No active airdrop");
        require(!userClaim.claimed, "Already claimed");

        // Check the signature
        bytes32 message = keccak256(abi.encode(address(this), _serverId, _roleId, _tokenAddress, msg.sender))
            .toEthSignedMessageHash();
        require(message.recover(_signature) == bot, "Not valid signature");

        userClaim.claimed = true;

        // Mint the NFT from the data and send it to the msg.sender
        IDCRoleToken(_tokenAddress).safeMint(msg.sender, _serverId, _roleId);
        emit Claimed(_serverId, _roleId, _tokenAddress, msg.sender);
    }

    /// @notice Grants permission to an address to claim an NFT.
    /// @dev This function can be used to distribute NFTs after the arirdrop is stopped.
    /// @param _signature Signature created by the bot.
    /// @param _serverId Id of the Discord server.
    /// @param _roleId Discord role Id.
    /// @param _user Address that can claim the NFT.
    /// @param _contractId Id of the token contract deployed by the server owner.
    function grant(
        bytes calldata _signature,
        string calldata _serverId,
        string calldata _roleId,
        address _user,
        uint256 _contractId
    ) external whenNotPaused {
        require(_contractId < numOfDeployedContracts[msg.sender], "Invalid NFT token");
        address roleToken = contractsByDeployer[msg.sender][_contractId];

        // Check the signature
        bytes32 message = keccak256(abi.encode(address(this), _serverId, _roleId, _user, roleToken, msg.sender))
            .toEthSignedMessageHash();
        require(message.recover(_signature) == bot, "Not valid signature");
        require(claimables[_serverId][_roleId][roleToken].dropped, "No Token for this role");

        claims[_user][_serverId][_roleId][roleToken].approved = true;

        emit Granted(_user, _serverId, _roleId, roleToken);
    }

    /// @notice stops the contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice restarts the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Retuns information of an airdrop by name.
    /// @param _dropName Name of the airdrop.
    function getDataOfDrop(string calldata _dropName)
        external
        view
        returns (
            string memory,
            string[] memory,
            address
        )
    {
        Drop storage drop = dropsByName[_dropName];
        return (drop.serverId, drop.roleIds, drop.tokenAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IDCRoleTokenFactory {
    function deployTokenContract(
        string calldata _tokenName,
        string calldata _tokenSymbol,
        string calldata _externalUrl
    ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IDCRoleToken {
    function addRoleData(
        string calldata _serverId,
        string calldata _roleId,
        string calldata _tokenImageHash,
        string calldata _tokenName,
        string[] calldata _traitTypes,
        string[] calldata _values
    ) external;

    function safeMint(
        address _to,
        string calldata _serverId,
        string calldata _roleId
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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