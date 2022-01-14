// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./interfaces/ICollabFactory.sol";
import "./interfaces/ICollab.sol";

contract MetaCollabFactory is ICollabFactory {
    uint256 public collabCount = 0;
    mapping(uint256 => address) internal _collabs;
    mapping(address => uint256) public flatFees;

    event LogNewCollab(uint256 indexed index, address collab);
    event UpdateFlatFee(
        address indexed resolver,
        uint256 indexed flatFee,
        bytes32 details
    );

    address public immutable implementation;

    constructor(address _implementation) {
        require(_implementation != address(0), "invalid implementation");
        implementation = _implementation;
    }

    function _newCollab(
        address _collabAddress,
        address _funder,
        address _doer
    ) internal {
        ICollab(_collabAddress).init(_funder, _doer, address(this));

        _collabs[collabCount] = _collabAddress;
        emit LogNewCollab(collabCount, _collabAddress);

        collabCount++;
    }

    function create(address _funder, address _doer)
        external
        override
        returns (address)
    {
        address collabAddress = Clones.clone(implementation);

        _newCollab(collabAddress, _funder, _doer);

        return collabAddress;
    }

    function predictDeterministicAddress(bytes32 _salt)
        external
        view
        override
        returns (address)
    {
        return Clones.predictDeterministicAddress(implementation, _salt);
    }

    function createDeterministic(
        address _funder,
        address _doer,
        bytes32 _salt
    ) external override returns (address) {
        address collabAddress = Clones.cloneDeterministic(
            implementation,
            _salt
        );

        _newCollab(collabAddress, _funder, _doer);

        return collabAddress;
    }

    function getCollabAddress(uint256 _index) public view returns (address) {
        return _collabs[_index];
    }

    function updateFlatFee(uint256 _flatFee, bytes32 _hash) external {
        flatFees[msg.sender] = _flatFee;
        emit UpdateFlatFee(msg.sender, _flatFee, _hash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

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
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
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
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
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
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICollabFactory {
    function create(address _funder, address _doer) external returns (address);

    function createDeterministic(
        address _funder,
        address _doer,
        bytes32 _salt
    ) external returns (address);

    function predictDeterministicAddress(bytes32 _salt)
        external
        returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface ICollab {
    function init(
        address _funder,
        address _doer,
        address _feeStore
    ) external;

    function createNewGig(bytes calldata _data, bytes calldata _signatures)
        external;

    function startNewGig(bytes calldata _data, bytes calldata _signatures)
        external;

    function startGig(uint256 _gigId) external;

    function cancelGig(uint256 _gigId) external;

    function completeGig(bytes calldata _data, bytes calldata _signatures)
        external;

    function lockGig(uint256 _gigId) external payable;

    function resolveGig(
        uint256 _gigId,
        uint8 _funderShare,
        uint8 _doerShare,
        uint8[3] calldata _thirdPartyRatio,
        bytes calldata hash
    ) external;

    function updateGigHash(bytes calldata _data, bytes calldata _signatures)
        external;

    function updateGigResolver(bytes calldata _data, bytes calldata _signatures)
        external;

    function updateThirdParty(uint256 _gigId, address _thirdParty) external;
}