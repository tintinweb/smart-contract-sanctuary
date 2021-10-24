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
///@notice Zapper DCA (Dollar-Cost Averaging) Vault Factory.
// SPDX-License-Identifier: GPL-2.0

pragma solidity 0.8.4;
import "../oz/0.8.0/proxy/Clones.sol";

interface IDCAVault {
    function initialize(
        address _principalToken,
        address _wantToken,
        address _principalTokenVaultAddress,
        address _principalTokenVaultWrapper,
        address _wantTokenVaultAddress, // address(0) if doesn't exist
        address _wantTokenVaultWrapper // address(0) if doesn't exist
    ) external;
}

interface IDCARegistry {
    function addVault(address vault) external;

    function owner() external view returns (address);
}

contract Infuze_Factory_V1 {
    // implementation address for dca vaults minimal proxy
    // vault version -> implementation address
    mapping(string => address) public implementation;
    // registry to keep track of all dca vaults
    IDCARegistry public registry;

    // Fee collector address
    address public collector = 0x3CE37278de6388532C3949ce4e886F365B14fB56;
    // Mapping from keeper address to their fee address
    mapping(address => address) public approvedKeepers;
    // Performance fees in bps (i.e. 100 is 1%)
    uint256 public performanceFee;
    // Keeper fees in bps (i.e. 100 is 1%)
    uint256 public keeperFee;
    // Max fee is 20%
    uint256 constant MAX_FEE = 2000;
    // 100% in bps
    uint256 constant BPS_BASE = 10000;

    // ratio in bps to actually deposit (i.e. 9500 is deposit 95% of tokens)
    uint256 public toDepositBuffer;

    // Mapping from Zap/swap address to approval status
    mapping(address => bool) public approvedTargets;

    constructor(address _registry) {
        registry = IDCARegistry(_registry);
    }

    modifier onlyOwner() {
        require(msg.sender == registry.owner(), "Caller is not owner");
        _;
    }

    function deployVault(
        string memory _vaultVersion,
        address _principalToken,
        address _wantToken,
        address _principalTokenVaultAddress,
        address _principalTokenVaultWrapper,
        address _wantTokenVaultAddress, // address(0) if doesn't exist
        address _wantTokenVaultWrapper // address(0) if doesn't exist
    ) external onlyOwner returns (address) {
        address deployedVaultAddress =
            Clones.clone(implementation[_vaultVersion]);
        IDCAVault(deployedVaultAddress).initialize(
            _principalToken,
            _wantToken,
            _principalTokenVaultAddress,
            _principalTokenVaultWrapper,
            _wantTokenVaultAddress,
            _wantTokenVaultWrapper
        );

        // add to registry
        registry.addVault(deployedVaultAddress);

        return (deployedVaultAddress);
    }

    function owner() external view returns (address) {
        return registry.owner();
    }

    function setImplementation(
        string memory _vaultVersion,
        address _implementation
    ) external onlyOwner {
        require(_implementation != address(0));
        implementation[_vaultVersion] = _implementation;
    }

    function setApprovedTargets(
        address[] calldata targets,
        bool[] calldata isApproved
    ) external onlyOwner {
        require(targets.length == isApproved.length, "Invalid input length");

        for (uint256 i = 0; i < targets.length; i++) {
            approvedTargets[targets[i]] = isApproved[i];
        }
    }

    function setPerformanceFees(uint256 _performanceFee) external onlyOwner {
        require(_performanceFee + keeperFee <= MAX_FEE);
        performanceFee = _performanceFee;
    }

    function setKeeperFee(uint256 _keeperFee) external onlyOwner {
        require(performanceFee + _keeperFee <= MAX_FEE);
        keeperFee = _keeperFee;
    }

    function setApprovedKeepers(
        address[] calldata keepers,
        address[] calldata feeAddress
    ) external onlyOwner {
        require(keepers.length == feeAddress.length, "Invalid Input length");

        for (uint256 i = 0; i < keepers.length; i++) {
            approvedKeepers[keepers[i]] = feeAddress[i];
        }
    }

    function setToDepositBuffer(uint256 _toDepositBuffer) external onlyOwner {
        require(_toDepositBuffer <= BPS_BASE);
        toDepositBuffer = _toDepositBuffer;
    }

    function updateCollector(address _collector) external onlyOwner {
        collector = _collector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt)
        internal
        returns (address instance)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000
            )
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}