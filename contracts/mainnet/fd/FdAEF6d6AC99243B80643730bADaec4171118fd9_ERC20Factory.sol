// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {IERC20Factory, IERC20FactoryEvents} from "./interface/IERC20Factory.sol";
import {IOwnableEvents} from "../../lib/Ownable.sol";
import {IERC20Events} from "./interface/IERC20.sol";
import {Clones} from "../Clones.sol";

interface IERC20 {
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
 * @notice The `ERC20Factory` contract deploys ERC20 clones. After deployment, the
 * factory calls `initialize` to set up the ERC20 metadata and mint the initial total
 * supply to the owner's wallet.
 * @author MirrorXYZ
 */
contract ERC20Factory is
    IERC20Factory,
    IERC20FactoryEvents,
    IERC20Events,
    IOwnableEvents
{
    /// @notice Address that holds the clone implementation
    address public immutable implementation;

    constructor(address implementation_) {
        implementation = implementation_;
    }

    //======== Deploy function =========

    /// @notice Deploy an ERC20 clone.
    /// @param owner the owner of the ERC20 token
    /// @param name_ the ERC20 metadata name parameter
    /// @param symbol_ the ERC20 metadata symbol parameter
    /// @param totalSupply_ the ERC20 token initial supply, minted to `owner`
    /// @param decimals_ the ERC20 token decimals
    /// @param nonce an additional entropy input to the clones salt
    function create(
        address owner,
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint8 decimals_,
        uint256 nonce
    ) external override returns (address erc20Clone) {
        erc20Clone = Clones.cloneDeterministic(
            implementation,
            keccak256(abi.encode(owner, name_, symbol_, totalSupply_, nonce))
        );

        IERC20(erc20Clone).initialize(
            owner,
            name_,
            symbol_,
            totalSupply_,
            decimals_
        );

        emit ERC20Deployed(erc20Clone, name_, symbol_, owner);
    }

    function predictDeterministicAddress(address implementation_, bytes32 salt)
        external
        view
        override
        returns (address)
    {
        return
            Clones.predictDeterministicAddress(
                implementation_,
                salt,
                address(this)
            );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface IERC20FactoryEvents {
    /// @notice New ERC20 clone deployed
    event ERC20Deployed(
        address clone,
        string name,
        string symbol,
        address operator
    );
}

interface IERC20Factory {
    /// @notice Deploy a new clone
    function create(
        address operator,
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint8 decimals_,
        uint256 nonce
    ) external returns (address erc20Clone);

    function predictDeterministicAddress(address logic_, bytes32 salt)
        external
        view
        returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface IOwnableEvents {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

contract Ownable is IOwnableEvents {
    address public owner;
    address private nextOwner;

    // modifiers

    modifier onlyOwner() {
        require(isOwner(), "caller is not the owner.");
        _;
    }

    modifier onlyNextOwner() {
        require(isNextOwner(), "current owner must set caller as next owner.");
        _;
    }

    /**
     * @dev Initialize contract by setting transaction submitter as initial owner.
     */
    constructor(address owner_) {
        owner = owner_;
        emit OwnershipTransferred(address(0), owner);
    }

    /**
     * @dev Initiate ownership transfer by setting nextOwner.
     */
    function transferOwnership(address nextOwner_) external onlyOwner {
        require(nextOwner_ != address(0), "Next owner is the zero address.");

        nextOwner = nextOwner_;
    }

    /**
     * @dev Cancel ownership transfer by deleting nextOwner.
     */
    function cancelOwnershipTransfer() external onlyOwner {
        delete nextOwner;
    }

    /**
     * @dev Accepts ownership transfer by setting owner.
     */
    function acceptOwnership() external onlyNextOwner {
        delete nextOwner;

        owner = msg.sender;

        emit OwnershipTransferred(owner, msg.sender);
    }

    /**
     * @dev Renounce ownership by setting owner to zero address.
     */
    function renounceOwnership() external onlyOwner {
        _renounceOwnership();
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    /**
     * @dev Returns true if the caller is the next owner.
     */
    function isNextOwner() public view returns (bool) {
        return msg.sender == nextOwner;
    }

    function _setOwner(address previousOwner, address newOwner) internal {
        owner = newOwner;
        emit OwnershipTransferred(previousOwner, owner);
    }

    function _renounceOwnership() internal {
        emit OwnershipTransferred(owner, address(0));

        owner = address(0);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

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

interface IERC20 {
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external view returns (bytes32);

    function initialize(
        address operator_,
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint8 decimals_
    ) external returns (address);

    function setBurnable(bool canBurn) external;

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);

    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

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