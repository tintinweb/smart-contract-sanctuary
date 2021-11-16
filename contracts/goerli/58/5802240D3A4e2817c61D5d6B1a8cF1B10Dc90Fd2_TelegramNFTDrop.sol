// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../RoleDropBase.sol";
import "../interfaces/IDropCenter.sol";
import "./interfaces/ITelegramToken.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract TelegramNFTDrop is RoleDropBase {
    using ECDSA for bytes32;

    IDropCenter dropCenter;

    mapping(string => Drop) public dropsByUrl;
    // User -> Group ID -> TokenAddress
    mapping(string => mapping(string => mapping(address => bool))) public claims;
    mapping(address => mapping(string => mapping(address => bool))) public approvals;
    // Group ID -> TokenAddress
    mapping(string => mapping(address => Claimable)) public claimables;

    struct Data {
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
        string dropName;
        string groupId;
        address tokenAddress;
        uint256 contractId;
    }

    event NewTelegramDrop(string dropUrl, string groupId);
    event DropOnGroup(string indexed groupId, string dropUrl);
    event Claimed(string indexed groupId, address indexed tokenContract, address user);
    event Granted(address indexed user, string groupId, address tokenContract);

    /// @param _dropCenterAddress The address of the drop center contract.
    /// @param _botAddress The address of the bot creating the signatures.
    /// @param _externalUrl Base url of the NFT page.
    constructor(
        address _dropCenterAddress,
        address _botAddress,
        string memory _externalUrl
    ) {
        dropCenter = IDropCenter(_dropCenterAddress);
        bot = _botAddress;
        externalUrl = _externalUrl;
    }

    /// @notice Creates a new airdrop for a Telegram group.
    /// @param _signature Signature created by the bot.
    /// @param _dropUrl Url of the airdrop.
    /// @param _dropName Name of the airdrop.
    /// @param _groupId Id of the Telegram group.
    /// @param _data Data of the NFT for the telegram group.
    /// @param _contractId Id of the token contract deployed by the server owner.
    function newAirdrop(
        bytes memory _signature,
        string memory _dropUrl,
        string memory _dropName,
        string memory _groupId,
        Data memory _data,
        uint256 _contractId
    ) external whenNotPaused {
        // Check the signature
        bytes32 message = keccak256(abi.encode(address(this), _groupId, _dropUrl, msg.sender)).toEthSignedMessageHash();
        require(message.recover(_signature) == bot, "Not valid signature");
        require(bytes(dropsByUrl[_dropUrl].dropName).length == 0, "Drop already exists");
        require(_contractId < numOfDeployedContracts[msg.sender], "Invalid NFT token");

        address roleToken = contractsByDeployer[msg.sender][_contractId];
        require(!claimables[_groupId][roleToken].dropped, "Group already has a drop");
        require(IOwnable(roleToken).owner() == address(this), "Token owner is not the contract");

        ITelegramToken(roleToken).addGroupData(
            _groupId,
            _data.tokenImageHash,
            _data.NFTName,
            _data.traitTypes,
            _data.values
        );

        Drop memory drop;
        Claimable memory claimable;

        drop.dropName = _dropName;
        drop.groupId = _groupId;
        drop.tokenAddress = roleToken;
        drop.contractId = _contractId;

        dropCenter.newDrop(_dropUrl);
        dropsByUrl[_dropUrl] = drop;

        claimable.dropped = true;
        claimable.active = true;

        claimables[_groupId][roleToken] = claimable;

        emit NewTelegramDrop(_dropUrl, _groupId);
        emit DropOnGroup(_groupId, _dropUrl);
    }

    /// @notice Stops the active airdrop for the given roles.
    /// @dev If an airdrop is stopped it CAN NOT BE RESTARTED for that role.
    /// @param _signature Signature created by the bot.
    /// @param _dropUrl Url of the Drop.
    function stopAirdrop(bytes memory _signature, string memory _dropUrl) external {
        Drop storage drop = dropsByUrl[_dropUrl];
        string memory groupId = drop.groupId;
        address roleToken = contractsByDeployer[msg.sender][drop.contractId];
        require(claimables[groupId][roleToken].active, "No active airdrop");

        // Check the signature
        bytes32 message = keccak256(abi.encode(address(this), groupId, roleToken, msg.sender, "stop"))
            .toEthSignedMessageHash();
        require(message.recover(_signature) == bot, "Not valid signature");

        claimables[groupId][roleToken].active = false;
    }

    /// @notice Mints an NFT for the user linked to the given group.
    /// @param _signature Signature created by the bot.
    /// @param _groupId Id of the Telegram group.
    /// @param _userId Hash of the user Id.
    /// @param _tokenAddress Address of the NFT contract.
    function claim(
        bytes memory _signature,
        string memory _groupId,
        string memory _userId,
        address _tokenAddress
    ) external whenNotPaused {
        require(
            claimables[_groupId][_tokenAddress].active || approvals[msg.sender][_groupId][_tokenAddress],
            "No active airdrop"
        );
        require(!claims[_userId][_groupId][_tokenAddress], "Already claimed");
        require(IOwnable(_tokenAddress).owner() == address(this), "Token owner is not the contract");

        // Check the signature
        bytes32 message = keccak256(abi.encode(address(this), _groupId, _tokenAddress, _userId, msg.sender))
            .toEthSignedMessageHash();
        require(message.recover(_signature) == bot, "Not valid signature");

        claims[_userId][_groupId][_tokenAddress] = true;

        // Mint the NFT from the data and send it to the msg.sender
        ITelegramToken(_tokenAddress).safeMint(msg.sender, _groupId);
        emit Claimed(_groupId, _tokenAddress, msg.sender);
    }

    /// @notice Grants permission to an address to claim an NFT.
    /// @dev This function can be used to distribute NFTs after the arirdrop is stopped.
    /// @param _signature Signature created by the bot.
    /// @param _groupId Id of the Telegram group.
    /// @param _user Address that can claim the NFT.
    /// @param _contractId Id of the token contract deployed by the server owner.
    function grant(
        bytes memory _signature,
        string memory _groupId,
        address _user,
        uint256 _contractId
    ) external whenNotPaused {
        require(_contractId < numOfDeployedContracts[msg.sender], "Invalid NFT token");
        address roleToken = contractsByDeployer[msg.sender][_contractId];
        require(IOwnable(roleToken).owner() == address(this), "Token owner is not the contract");

        // Check the signature
        bytes32 message = keccak256(abi.encode(address(this), _groupId, _user, roleToken, msg.sender))
            .toEthSignedMessageHash();
        require(message.recover(_signature) == bot, "Not valid signature");
        require(claimables[_groupId][roleToken].dropped, "No Token for this group");

        approvals[_user][_groupId][roleToken] = true;

        emit Granted(_user, _groupId, roleToken);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IRoleTokenFactory {
    function deployTokenContract(
        string calldata _tokenName,
        string calldata _tokenSymbol,
        string calldata _externalUrl
    ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IOwnable {
    function owner() external returns (address);

    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IDropCenter {
    function newDrop(string calldata _dropUrl) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ITelegramToken {
    function addGroupData(
        string calldata _groupId,
        string calldata _tokenImageHash,
        string calldata _NFTName,
        string[] calldata _traitTypes,
        string[] calldata _values
    ) external;

    function safeMint(address _to, string calldata _groupId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IOwnable.sol";
import "./interfaces/IRoleTokenFactory.sol";

contract RoleTokenManager is Ownable {
    address public tokenFactory;
    string public externalUrl;

    mapping(address => uint256) public numOfDeployedContracts;
    mapping(address => mapping(uint256 => address)) public contractsByDeployer;

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
        address roleToken = IRoleTokenFactory(tokenFactory).deployTokenContract(_tokenName, _tokenSymbol, externalUrl);
        contractsByDeployer[msg.sender][numOfDeployedContracts[msg.sender]] = roleToken;
        numOfDeployedContracts[msg.sender] += 1;
    }

    /// @notice Transfers ownership of the toke contract.
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./RoleTokenManager.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract RoleDropBase is RoleTokenManager, Pausable {
    address internal bot;

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