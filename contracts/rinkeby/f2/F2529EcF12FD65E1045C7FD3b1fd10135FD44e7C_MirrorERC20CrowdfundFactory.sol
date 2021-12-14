// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import {MirrorProxy} from "../lib/MirrorProxy.sol";
import {IMirrorERC20CrowdfundFactory, IMirrorERC20CrowdfundFactoryEvents} from "./interface/IMirrorERC20CrowdfundFactory.sol";
import {IOwnableEvents} from "../lib/Ownable.sol";
import {IERC20Events} from "./interface/IERC20.sol";

interface IMirrorERC20Logic {
    /// @notice Register new proxy and initialize metadata
    function initialize(
        address owner_,
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint8 decimals_
    ) external;
}

/**
 * @title MirrorERC20CrowdfundFactory
 * @author MirrorXYZ
 */
contract MirrorERC20CrowdfundFactory is
    IMirrorERC20CrowdfundFactory,
    IMirrorERC20CrowdfundFactoryEvents,
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
        uint8 decimals_
    ) external override returns (address erc20Proxy) {
        bytes memory initializationData = abi.encodeWithSelector(
            IMirrorERC20Logic.initialize.selector,
            owner,
            name_,
            symbol_,
            totalSupply_,
            decimals_
        );

        erc20Proxy = address(
            new MirrorProxy{salt: keccak256(abi.encode(owner, name_, symbol_))}(
                logic,
                initializationData
            )
        );

        emit ERC20ProxyDeployed(erc20Proxy, name_, symbol_, owner);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

/**
 * @title MirrorProxy
 * @author MirrorXYZ
 * The MirrorProxy contract is used to deploy minimal proxies.
 */
contract MirrorProxy {
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @notice Initializes a proxy by delegating logic to the implementation,
     * and reverts if the call is not successful. Stores implementation logic.
     * @param implementation - the implementation holds the logic for all proxies
     * @param initializationData - initialization call
     */
    constructor(address implementation, bytes memory initializationData) {
        // Delegatecall into the implementation, supplying initialization calldata.
        (bool ok, ) = implementation.delegatecall(initializationData);

        // Revert and include revert data if delegatecall to implementation reverts.
        if (!ok) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        assembly {
            sstore(_IMPLEMENTATION_SLOT, implementation)
        }
    }

    /**
     * @notice When any function is called on this contract, we delegate to
     * the logic contract stored in the implementation storage slot.
     */
    fallback() external payable {
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(
                gas(),
                sload(_IMPLEMENTATION_SLOT),
                ptr,
                calldatasize(),
                0,
                0
            )
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface IMirrorERC20CrowdfundFactoryEvents {
    /// @notice New ERC20 proxy deployed
    event ERC20ProxyDeployed(
        address proxy,
        string name,
        string symbol,
        address operator
    );
}

interface IMirrorERC20CrowdfundFactory {
    /// @notice Deploy a new proxy
    function create(
        address operator,
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint8 decimals_
    ) external returns (address erc20Proxy);
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
        owner = address(0);

        emit OwnershipTransferred(owner, address(0));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

interface IERC20Events {
    /// @notice EIP-20 Mint event
    event Mint(address indexed to, uint256 amount);

    /// @notice EIP-20 approval event
    event Approval(
        address indexed from,
        address indexed spender,
        uint256 value
    );

    /// @notice EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 value);
}