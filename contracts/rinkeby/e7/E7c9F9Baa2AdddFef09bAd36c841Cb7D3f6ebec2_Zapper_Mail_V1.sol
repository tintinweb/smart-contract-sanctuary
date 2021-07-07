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

    function addr(bytes32 _node) external view returns (address);
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

contract SignatureVerifier {
    address public _signer;

    constructor(address signer) {
        _signer = signer;
    }

    function verify(
        address account,
        string calldata publicKey,
        bytes memory signature
    ) internal view returns (bool) {
        bytes32 messageHash = getMessageHash(account, publicKey);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function getMessageHash(address account, string calldata publicKey)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(account, publicKey));
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

import "../oz/0.8.0/access/Ownable.sol";
import "./Signature_Verifier.sol";
import "./ENS_Registry.sol";
import "./ENS_Resolver.sol";

// Rinkeby: Public Resolver: 0xf6305c19e814d2a75429fd637d01f7ee0e77d615
// Rinkeby: Registry: 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e

contract Zapper_Mail_V1 is SignatureVerifier, Ownable {
    bytes32 private constant EMPTY_NAME_HASH = 0x00;
    string private constant TOP_DOMAIN_NAME = "eth";
    string private constant DOMAIN_NAME = "zappermail";

    bool public paused = false;
    EnsRegistry public registry;
    EnsResolver public resolver;

    event UserRegistered(
        bytes32 indexed usernameHash,
        address indexed addr,
        string username,
        string publicKey
    );
    event EmailSent(address indexed from, address indexed to, string mailHash);
    event ContactsUpdated(bytes32 indexed usernameHash, string fileHash);

    constructor(
        address _signer,
        EnsRegistry _registry,
        EnsResolver _resolver
    ) SignatureVerifier(_signer) {
        registry = _registry;
        resolver = _resolver;
    }

    modifier pausable {
        if (paused) {
            revert("Paused");
        } else {
            _;
        }
    }

    /**
     * @dev Pause or unpause the minting and creation of NFTs
     */
    function pause() public onlyOwner {
        paused = !paused;
    }

    /**
     * @dev The contract owner can take away the ownership of any domain owned by this contract.
     * @param _node - namehash of the domain
     * @param _owner - new owner for the domain
     */
    function transferDomainOwnership(bytes32 _node, address _owner)
        public
        onlyOwner
    {
        registry.setOwner(_node, _owner);
    }

    /**
     * @dev Returns the node of the domain managed by this subdomain registrar
     */
    function baseNode() public pure returns (bytes32) {
        bytes32 topDomainLabelHash =
            keccak256(abi.encodePacked(TOP_DOMAIN_NAME));
        bytes32 topDomainNamehash =
            keccak256(abi.encodePacked(EMPTY_NAME_HASH, topDomainLabelHash));
        bytes32 domainLabelHash = keccak256(abi.encodePacked(DOMAIN_NAME));
        bytes32 domainNamehash =
            keccak256(abi.encodePacked(topDomainNamehash, domainLabelHash));
        return domainNamehash;
    }

    function baseNodeOwner() public view returns (address) {
        bytes32 _baseNode = baseNode();
        return registry.owner(_baseNode);
    }

    /**
     * @dev Allows to update to new ENS registry.
     * @param _registry The address of new ENS registry to use.
     */
    function updateRegistry(EnsRegistry _registry) public onlyOwner {
        require(
            registry != _registry,
            "new registry should be different from old"
        );
        registry = _registry;
    }

    /**
     * @dev Allows to update to new ENS resolver.
     * @param _resolver The address of new ENS resolver to use.
     */
    function updateResolver(EnsResolver _resolver) public onlyOwner {
        require(
            resolver != _resolver,
            "new resolver should be different from old"
        );
        resolver = _resolver;
    }

    /**
     * @dev Registers a username to an address, such that the address will own a subdomain of zappermail.eth
     * i.e.: If a user registers "joe", they will own "joe.zappermail.eth"
     * @param _account - Address of the new owner of the username
     * @param _username - Username being requested
     * @param _publicKey - The Zapper mail encryption public key for this username
     * @param _signature - Verified signature granting account the subdomain
     */
    function registerUser(
        address _account,
        string calldata _username,
        string calldata _publicKey,
        bytes calldata _signature
    ) external pausable {
        // Confirm that the signature matches that of the sender
        require(
            verify(_account, _publicKey, _signature),
            "Err: Invalid Signature"
        );

        // Build the name hash of the subdomain we want to register (implementation detail of ENS)
        bytes32 topDomainLabelHash =
            keccak256(abi.encodePacked(TOP_DOMAIN_NAME));
        bytes32 topDomainNamehash =
            keccak256(abi.encodePacked(EMPTY_NAME_HASH, topDomainLabelHash));
        bytes32 domainLabelHash = keccak256(abi.encodePacked(DOMAIN_NAME));
        bytes32 domainNamehash =
            keccak256(abi.encodePacked(topDomainNamehash, domainLabelHash));
        bytes32 subdomainLabelHash = keccak256(abi.encodePacked(_username));
        bytes32 subdomainNamehash =
            keccak256(abi.encodePacked(domainNamehash, subdomainLabelHash));

        // Require that the subdomain is not already owned or owned by the caller
        require(
            registry.owner(subdomainNamehash) == address(0) ||
                registry.owner(subdomainNamehash) == _account,
            "Err: Subdomain already owned"
        );

        // Take ownership of the subdomain and configure it
        registry.setSubnodeOwner(
            domainNamehash,
            subdomainLabelHash,
            address(this)
        );
        registry.setResolver(subdomainNamehash, address(resolver));
        resolver.setAddr(subdomainNamehash, _account);
        registry.setOwner(subdomainNamehash, _account);

        // Emit event to index users on the backend
        bytes32 usernameHash = keccak256(bytes(_username));
        emit UserRegistered(usernameHash, _account, _username, _publicKey);
    }

    function sendEmail(address recipient, string calldata mailHash)
        external
        pausable
    {
        emit EmailSent(tx.origin, recipient, mailHash);
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

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}