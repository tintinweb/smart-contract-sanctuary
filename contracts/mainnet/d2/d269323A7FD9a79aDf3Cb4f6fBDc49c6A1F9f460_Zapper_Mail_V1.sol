// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2020 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice Zapper Mail implementation, based heavily on Melon Mail from Melonport
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;

/**
 * @title EnsRegistry
 * @dev Extract of the interface for ENS Registry
 */
interface EnsRegistry {
    function setOwner(bytes32 _node, address _owner) external;

    function setSubnodeOwner(
        bytes32 _node,
        bytes32 _label,
        address _owner
    ) external;

    function setResolver(bytes32 _node, address _resolver) external;

    function owner(bytes32 _node) external view returns (address);

    function resolver(bytes32 _node) external view returns (address);
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2020 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice Zapper Mail implementation, based heavily on Melon Mail from Melonport
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;

/**
 * @title EnsResolver
 * @dev Extract of the interface for ENS Resolver
 */
interface EnsResolver {
    function setAddr(bytes32 _node, address _addr) external;

    function setText(
        bytes32 node,
        string calldata key,
        string calldata value
    ) external;

    function addr(bytes32 _node) external view returns (address);

    function text(bytes32 node, string calldata key)
        external
        view
        returns (string memory);
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper
// Copyright (c) 2018 Tasuku Nakamura

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract checks if a message has been signed by a verified signer via personal_sign.
// SPDX-License-Identifier: GPLv2

pragma solidity ^0.8.0;

import "../oz/0.8.0/access/Ownable.sol";

contract SignatureVerifier is Ownable {
    address public signer;

    event SignerUpdated(address indexed signer);

    constructor(address _signer) {
        signer = _signer;
    }

    function verifyAccountAndPublicKeyPair(
        address account,
        string calldata publicKey,
        bytes memory signature
    ) internal view returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(account, publicKey));
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature) == signer;
    }

    function verifyUserDataPair(
        address account,
        string calldata key,
        string calldata value,
        bytes memory signature
    ) internal view returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(account, key, value));
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature) == signer;
    }

    function updateSigner(address _signer) external onlyOwner {
        require(signer != _signer, "Err: New signer should be different");
        signer = _signer;
        emit SignerUpdated(_signer);
    }

    function getEthSignedMessageHash(bytes32 messageHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    messageHash
                )
            );
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory signature)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(signature.length == 65, "invalid signature length");

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
    }
}

// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice Zapper Mail implementation with inspiration from Melon Mail.
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;

import "../oz/0.8.0/access/Ownable.sol";
import "./Signature_Verifier.sol";
import "./ENS_Registry.sol";
import "./ENS_Resolver.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

contract Zapper_Mail_V1 is SignatureVerifier {
    EnsRegistry public registry;
    EnsResolver public resolver;
    bytes32 public baseNode;
    bool public paused = false;
    mapping(address => bytes32) public addressToNode;

    event UserRegistered(
        bytes32 indexed baseNode,
        bytes32 indexed usernameHash,
        address indexed addr,
        string username,
        string publicKey
    );
    event UserUnregistered(
        bytes32 indexed baseNode,
        bytes32 indexed usernameHash,
        address indexed addr,
        string username
    );
    event MessageSent(
        bytes32 indexed baseNode,
        address indexed from,
        address indexed to,
        string mailHash
    );
    event RegistryUpdated(address indexed registry);
    event ResolverUpdated(address indexed resolver);
    event BaseNodeUpdated(bytes32 indexed basenode);

    constructor(
        address _signer,
        EnsRegistry _registry,
        EnsResolver _resolver,
        bytes32 _baseNode
    ) SignatureVerifier(_signer) {
        registry = _registry;
        resolver = _resolver;
        baseNode = _baseNode;
    }

    modifier pausable {
        if (paused) {
            revert("Paused");
        } else {
            _;
        }
    }

    /**
     * @dev Pause or unpause the mail functionality
     */
    function pause() external onlyOwner {
        paused = !paused;
    }

    /**
     * @dev Transfer ownership of any domain or subdomain owned by this address
     * @param _node - namehash of the domain or subdomain to transfer
     * @param _owner - new owner for the ENS domain
     */
    function transferDomainOwnership(bytes32 _node, address _owner)
        external
        onlyOwner
    {
        registry.setOwner(_node, _owner);
    }

    /**
     * @dev Returns the node for the subdomain specified by the username
     */
    function node(string calldata _username) public view returns (bytes32) {
        return
            keccak256(abi.encodePacked(baseNode, keccak256(bytes(_username))));
    }

    /**
     * @dev Updates to new ENS registry.
     * @param _registry The address of new ENS registry to use.
     */
    function updateRegistry(EnsRegistry _registry) external onlyOwner {
        require(registry != _registry, "Err: New registry should be different");
        registry = _registry;
        emit RegistryUpdated(address(registry));
    }

    /**
     * @dev Allows to update to new ENS resolver.
     * @param _resolver The address of new ENS resolver to use.
     */
    function updateResolver(EnsResolver _resolver) external onlyOwner {
        require(resolver != _resolver, "Err: New resolver should be different");
        resolver = _resolver;
        emit ResolverUpdated(address(resolver));
    }

    /**
     * @dev Allows to update to new ENS base node.
     * @param _baseNode The new ENS base node to use.
     */
    function updateBaseNode(bytes32 _baseNode) external onlyOwner {
        require(baseNode != _baseNode, "Err: New node should be different");
        baseNode = _baseNode;
        emit BaseNodeUpdated(baseNode);
    }

    /**
     * @dev Registers a username to an address, such that the address will own a subdomain of zappermail.eth
     * i.e.: If a user registers "joe", they will own "joe.zappermail.eth"
     * @param _username - Username being requested
     * @param _publicKey - The Zapper mail encryption public key for this username
     * @param _signature - Verified signature granting account the subdomain
     */
    function registerUser(
        string calldata _username,
        string calldata _publicKey,
        bytes calldata _signature
    ) external pausable {
        bytes32 _node = node(_username);

        // Confirm that the signature matches that of the sender
        require(
            verifyAccountAndPublicKeyPair(msg.sender, _publicKey, _signature),
            "Err: Invalid Signature"
        );

        // Require that the subdomain is not already owned or owned by the previous implementation (migration)
        require(
            resolver.addr(_node) == address(0) ||
                resolver.addr(_node) == address(this) ||
                resolver.addr(_node) == msg.sender, // For migrations from previous contract deployments
            "Err: Subdomain already assigned"
        );

        // Require that the account does not already own a subdomain
        require(
            addressToNode[msg.sender] == "",
            "Err: Account already owns a subdomain"
        );

        // Take ownership of the subdomain and configure it
        bytes32 usernameHash = keccak256(bytes(_username));
        registry.setSubnodeOwner(baseNode, usernameHash, address(this));
        registry.setResolver(_node, address(resolver));
        resolver.setAddr(_node, msg.sender);
        registry.setOwner(_node, address(this));

        // Keep track of the associated node per account
        addressToNode[msg.sender] = _node;

        // Emit event to index registration on the backend
        emit UserRegistered(
            baseNode,
            usernameHash,
            msg.sender,
            _username,
            _publicKey
        );
    }

    function setUserData(
        string calldata _username,
        string calldata _key,
        string calldata _value,
        bytes calldata _signature
    ) external pausable {
        bytes32 _node = node(_username);

        // Confirm that the signature matches that of the sender
        require(
            verifyUserDataPair(msg.sender, _key, _value, _signature),
            "Err: Invalid Signature"
        );

        // Require that the subdomain is owned by this account
        require(
            _node == addressToNode[msg.sender] &&
                resolver.addr(_node) == msg.sender,
            "Err: Subdomain not assigned to account"
        );

        resolver.setText(_node, _key, _value);
    }

    function unregisterUser(string calldata _username) external pausable {
        bytes32 _node = node(_username);

        // Require that the subdomain is owned by this account
        require(
            _node == addressToNode[msg.sender] &&
                resolver.addr(_node) == msg.sender,
            "Err: Subdomain not assigned to account"
        );

        // Take ownership of the subdomain and configure it
        bytes32 usernameHash = keccak256(bytes(_username));
        registry.setSubnodeOwner(baseNode, usernameHash, address(this));
        resolver.setAddr(_node, address(0));
        registry.setOwner(_node, address(this));

        // Keep track of the associated node per account
        addressToNode[tx.origin] = "";

        // Emit event to index revocation on the backend
        emit UserUnregistered(baseNode, usernameHash, msg.sender, _username);
    }

    /**
     * @dev Sends a message to a user
     * @param _recipient - Address of the recipient of the message
     * @param _hash - IPFS hash of the message
     */
    function sendMessage(address _recipient, string calldata _hash)
        external
        pausable
    {
        emit MessageSent(baseNode, tx.origin, _recipient, _hash);
    }

    /**
     * @dev Batch sends a message to users
     * @param _recipients - Addresses of the recipients of the message
     * @param _hashes - IPFS hashes of the message
     */
    function batchSendMessage(
        address[] calldata _recipients,
        string[] calldata _hashes
    ) external pausable {
        require(
            _recipients.length == _hashes.length,
            "Err: Expected same number of recipients as hashes"
        );
        for (uint256 i = 0; i < _recipients.length; i++) {
            emit MessageSent(baseNode, tx.origin, _recipients[i], _hashes[i]);
        }
    }

    /**
     * @dev Emergency withdraw if anyone sends funds to this address
     * @param _tokens - Addresses of the tokens (or ETH as zero address) to withdraw
     */
    function withdrawTokens(address[] calldata _tokens) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (_tokens[i] == address(0)) {
                payable(owner()).transfer(address(this).balance);
            } else {
                uint256 qty = IERC20(_tokens[i]).balanceOf(address(this));
                IERC20(_tokens[i]).transfer(owner(), qty);
            }
        }
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

