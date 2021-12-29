/**
 *Submitted for verification at Etherscan.io on 2021-12-28
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface IERC20Factory {
    /// @notice Deploy a new proxy
    function create(
        address operator,
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint8 decimals_,
        uint256 nonce
    ) external returns (address erc20Proxy);
}

interface IERC20FactoryEvents {
    /// @notice New ERC20 proxy deployed
    event ERC20Deployed(
        address proxy,
        string name,
        string symbol,
        address operator
    );
}

interface IOwnableEvents {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

interface IERC20Events {
    /// @notice EIP-20 transfer event
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /// @notice EIP-20 approval event
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    /// @notice Mint event
    event Mint(address indexed _to, uint256 _value);
}

/**
 * @dev Copy of OpenZeppelin's Clones contract
 * https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
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

interface IERC20Logic {
    function initialize(
        address owner_,
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint8 decimals_
    ) external;
}

/**
 * @title ERC20Factory
 * @author MirrorXYZ
 */
contract ERC20Factory is
    IERC20Factory,
    IERC20FactoryEvents,
    IERC20Events,
    IOwnableEvents
{
    //======== Immutable Variables =========

    /// @notice Address that holds the proxy logic
    address public immutable logic;

    //======== Constructor =========

    constructor(address logic_) {
        logic = logic_;
    }

    //======== Deploy function =========

    function create(
        address owner,
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint8 decimals_,
        uint256 nonce
    ) external override returns (address erc20Proxy) {
        erc20Proxy = Clones.cloneDeterministic(
            logic,
            keccak256(abi.encode(owner, name_, symbol_, totalSupply_, nonce))
        );

        IERC20Logic(erc20Proxy).initialize(
            owner,
            name_,
            symbol_,
            totalSupply_,
            decimals_
        );

        emit ERC20Deployed(erc20Proxy, name_, symbol_, owner);
    }

    function predictDeterministicAddress(address logic_, bytes32 salt)
        external
        view
        returns (address)
    {
        return Clones.predictDeterministicAddress(logic_, salt, address(this));
    }
}