/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

/**
 * @title ERC-173 Contract Ownership Standard
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-173.md
 * Note: the ERC-165 identifier for this interface is 0x7f5828d0
 */
interface IERC173 {
    /**
     * @dev This emits when ownership of a contract changes.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @notice Get the address of the owner
     * @return The address of the owner.
     */
    function owner() external view returns (address);

    /**
     * @notice Set the address of the new owner of the contract
     * @param newOwner The address of the new owner of the contract
     */
    function transferOwnership(address newOwner) external;
}

/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function balanceOf(address target) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);
}

/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

interface IMulticall {
    function multicall(bytes[] calldata callData) external returns (bytes[] memory returnData);
}

/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

library Address {
    function isContract(address target) internal view returns (bool result) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            result := gt(extcodesize(target), 0)
        }
    }
}

/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "./Address.sol";

abstract contract Initializer {
    using Address for address;

    bool private _initialized;

    modifier initializer() {
        require(!_initialized || !address(this).isContract(), "Initializer/Already Initialized");
        _initialized = true;
        _;
    }
}

/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../interfaces/IMulticall.sol";

/**
 * @title Multicall
 * @author yoonsung.eth
 * @notice 컨트랙트가 가지고 있는 트랜잭션을 순서대로 실행시킬 수 있음.
 */
abstract contract Multicall is IMulticall {
    function multicall(bytes[] calldata callData) external override returns (bytes[] memory returnData) {
        returnData = new bytes[](callData.length);
        for (uint256 i = 0; i < callData.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(callData[i]);
            // Next 5 lines from https://ethereum.stackexchange.com/a/83577
            if (!success) {
                // revert called without a message
                if (result.length < 68) revert();
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            returnData[i] = result;
        }
    }
}

/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../interfaces/IERC173.sol";

/**
 * @title Ownership
 * @author yoonsung.eth
 * @notice 단일 Ownership을 가질 수 있도록 도와주는 추상 컨트랙트
 * @dev constructor 기반 컨트랙트에서는 생성 시점에 owner가 msg.sender로 지정되며,
 *      Proxy로 작동되는 컨트랙트의 경우 `__transferOwnership(address)`를 명시적으로 호출하여 owner를 지정하여야 한다.
 */
abstract contract Ownership is IERC173 {
    address public override owner;

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownership/Not-Authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function transferOwnership(address newOwner) external virtual override onlyOwner {
        require(newOwner != address(0), "Ownership/Not-Allowed-Zero");
        _transferOwnership(newOwner);
    }

    function resignOwnership() external virtual onlyOwner {
        delete owner;
        emit OwnershipTransferred(msg.sender, address(0));
    }

    function _transferOwnership(address newOwner) internal {
        address prev = owner;
        owner = newOwner;
        emit OwnershipTransferred(prev, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Origin by https://github.com/Uniswap/merkle-distributor
 */
pragma solidity ^0.8.0;

import "@beandao/contracts/interfaces/IERC20.sol";
import "@beandao/contracts/interfaces/IERC165.sol";
import {Initializer} from "@beandao/contracts/library/Initializer.sol";
import {Ownership, IERC173} from "@beandao/contracts/library/Ownership.sol";
import {Multicall, IMulticall} from "@beandao/contracts/library/Multicall.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleDistributor is Multicall, Ownership, Initializer, IERC165 {
    IERC20 public token;
    bytes32 public root;
    mapping(uint256 => uint256) private claimedIndex;

    event Claimed(uint256 index, address account, uint256 amount);
    event Finalized(address token, bytes32 merkleroot);

    function initialize(address tokenAddr, bytes32 merkleRoot) external initializer {
        _transferOwnership(msg.sender);
        token = IERC20(tokenAddr);
        root = merkleRoot;
    }

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedIndex[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedIndex[claimedWordIndex] = claimedIndex[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        require(!isClaimed(index), "MerkleDistributor/Already claimed");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, root, node), "MerkleDistributor/Invalid proof");

        // Mark it claimed and send the token.
        _setClaimed(index);
        token.transfer(account, amount);

        emit Claimed(index, account, amount);
    }

    /**
     * 클레임된 비트맵을 유지하면서, 새로운 트리를 등록합니다.
     */
    function updateTree(bytes32 merkleRoot) external onlyOwner {
        require(merkleRoot != bytes32(0), "MerkleDistributor/Invalid Input");
        root = merkleRoot;
    }

    /**
     * 배포 종료
     * 남은 토큰을 오너에게 전송하고, 가스를 낭비하지 않도록 MerkleRoot를 0으로 변경한다.
     */
    function finalize() external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
        root = bytes32(0);
        emit Finalized(address(token), root);
    }

    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return
            interfaceID == type(IERC165).interfaceId ||
            interfaceID == type(IERC173).interfaceId ||
            interfaceID == type(IMulticall).interfaceId;
    }
}