// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import {MirrorProxy} from "../../producers/mirror/MirrorProxy.sol";
import {IMirrorERC20Factory, IMirrorERC20FactoryEvents} from "./interface/IMirrorERC20Factory.sol";
import {IMirrorERC20ProxyStorageEvents} from "./interface/IMirrorERC20ProxyStorage.sol";

interface IERC20ProxyStorage {
    /// @notice Register new proxy and initialize metadata
    function initialize(
        address operator_,
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint8 decimals_
    ) external;
}

/**
 * @title MirrorERC20Factory
 * @author MirrorXYZ
 */
contract MirrorERC20Factory is
    IMirrorERC20Factory,
    IMirrorERC20FactoryEvents,
    IMirrorERC20ProxyStorageEvents
{
    /// @notice Address that holds the relay logic for proxies
    address public immutable relayer;

    //======== Constructor =========

    constructor(address relayer_) {
        relayer = relayer_;
    }

    //======== Deploy function =========

    function create(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint8 decimals_
    ) external override returns (address erc20Proxy) {
        address operator = payable(msg.sender);

        bytes memory initializationData = abi.encodeWithSelector(
            IERC20ProxyStorage.initialize.selector,
            operator,
            name_,
            symbol_,
            totalSupply_,
            decimals_
        );

        erc20Proxy = address(
            new MirrorProxy{
                salt: keccak256(abi.encode(operator, name_, symbol_))
            }(relayer, initializationData)
        );

        emit ERC20ProxyDeployed(erc20Proxy, name_, symbol_, operator);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title MirrorProxy
 * @author MirrorXYZ
 * The MirrorProxy contract is used to deploy minimal contracts for multiple
 * economic producers on the Mirror ecosystem (e.g. crowdfunds, editions). The
 * proxies are used with the proxy-relayer pattern. The proxy delegates calls
 * to a relayer contract that calls into the storage contract. The proxy uses the
 * EIP-1967 standard to store the "implementation" logic, which in our case is
 * the relayer contract. The relayer logic is directly stored into the standard
 * slot using `sstore` in the constructor, and read using `sload` in the fallback
 * function.
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
     * @notice Initializes a proxy by delegating logic to the relayer,
     * and reverts if the call is not successful. Stores relayer logic.
     * @param relayer - the relayer holds the logic for all proxies
     * @param initializationData - initialization call
     */
    constructor(address relayer, bytes memory initializationData) {
        // Delegatecall into the relayer, supplying initialization calldata.
        (bool ok, ) = relayer.delegatecall(initializationData);

        // Revert and include revert data if delegatecall to implementation reverts.
        if (!ok) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        assembly {
            sstore(_IMPLEMENTATION_SLOT, relayer)
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
pragma solidity 0.8.6;

interface IMirrorERC20FactoryEvents {
    event ERC20ProxyDeployed(
        address proxy,
        string name,
        string symbol,
        address operator
    );
}

interface IMirrorERC20Factory {
    /// @notice Deploy a new proxy
    function create(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint8 decimals_
    ) external returns (address erc20Proxy);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IMirrorERC20ProxyStorageEvents {
    /// @notice Emitted when a new proxy is initialized
    event NewProxy(address indexed proxy, address indexed operator);
}

interface IMirrorERC20ProxyStorage {
    function operator() external view returns (address);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Register new proxy and initialize metadata
    function initialize(
        address operator_,
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint8 decimals_
    ) external returns (address);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(
        address sender,
        address spender,
        uint256 value
    ) external returns (bool);

    function transfer(
        address sender,
        address to,
        uint256 value
    ) external returns (bool);

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

    function mint(
        address sender,
        address to,
        uint256 amount
    ) external;

    function setOperator(address sender, address newOperator) external;
}