// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Kit.sol";
import "./interfaces/IFilm.sol";

contract MyKit is InternetCameraKit {
    constructor()
        InternetCameraKit(
            "MyKit",
            "MYKIT",
            0xA8FE5585c337Fc1aC3EBbd7670Fed8D93A75ed62,
            IInternetCameraFilm.Configuration({
                price: 0,
                mintable: false,
                premint: 1000,
                maxSupply: 1000,
                startTime: 0,
                endTime: 0
            }),
            0x36E1b3B44a12265A2B0eAF20C4B421760a490BBa,
            0x81b38Aff07FDc4f9bEFF370F14433C5D75D8F6ea
        )
    {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IInternetCameraFilm {
    struct Configuration {
        bool mintable;
        uint256 price;
        uint256 premint;
        uint256 maxSupply;
        uint256 startTime;
        uint256 endTime;
    }

    error NotAuthorized();

    function initialize(
        string memory name,
        string memory symbol,
        address creator,
        address collection,
        Configuration memory config
    ) external;

    function collection() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IInternetCameraFilm} from "./interfaces/IFilm.sol";
import {IInternetCameraCollection} from "./interfaces/ICollection.sol";
import {IInternetCameraRegistry} from "./interfaces/IRegistry.sol";

contract InternetCameraKit {
    constructor(
        string memory name,
        string memory symbol,
        address filmImplementation,
        IInternetCameraFilm.Configuration memory filmConfig,
        address collectionImplementation,
        address registry
    ) {
        address film = Clones.clone(filmImplementation);
        address collection = Clones.clone(collectionImplementation);

        IInternetCameraFilm(film).initialize(
            name,
            symbol,
            msg.sender,
            collection,
            filmConfig
        );
        IInternetCameraCollection(collection).initialize(film, name, symbol);
        IInternetCameraRegistry(registry).register(film, collection);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IInternetCameraRegistry {
    struct Kit {
        address filmImplementation;
        address collectionImplementation;
    }

    function register(address film, address collection) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IInternetCameraCollection {
    event PostCreated(uint256 indexed tokenId, string ipfsHash);
    event PostRemoved(uint256 indexed tokenId);

    error NotAuthorized();

    function initialize(
        address film,
        string memory name,
        string memory symbol
    ) external;

    function filmAddress() external view returns (address);

    function totalSupply() external view returns (uint256);

    function post(
        address creator,
        uint256 tokenId,
        string memory ipfsHash
    ) external;
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