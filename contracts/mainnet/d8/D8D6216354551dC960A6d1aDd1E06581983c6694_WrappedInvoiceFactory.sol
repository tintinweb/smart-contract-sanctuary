// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./interfaces/IWrappedInvoice.sol";
import "./interfaces/IWrappedInvoiceFactory.sol";
import "./interfaces/ISmartInvoiceFactory.sol";

contract WrappedInvoiceFactory is IWrappedInvoiceFactory {
    uint256 public invoiceCount = 0;
    mapping(uint256 => address) internal _invoices;

    event LogNewWrappedInvoice(uint256 indexed index, address wrappedInvoice);

    address public immutable implementation;
    ISmartInvoiceFactory public immutable smartInvoiceFactory;

    constructor(address _implementation, address _smartInvoiceFactory) {
        require(_implementation != address(0), "invalid implementation");
        require(
            _smartInvoiceFactory != address(0),
            "invalid smartInvoiceFactory"
        );
        implementation = _implementation;
        smartInvoiceFactory = ISmartInvoiceFactory(_smartInvoiceFactory);
    }

    function _createSmartInvoice(SmartInvoiceInfo memory _info)
        internal
        returns (address)
    {
        return
            smartInvoiceFactory.create(
                _info.client,
                _info.provider,
                _info.resolverType,
                _info.resolver,
                _info.token,
                _info.amounts,
                _info.terminationTime,
                _info.details
            );
    }

    function _init(WrappedInvoiceInfo memory _info) internal {
        address smartInvoiceAddress =
            _createSmartInvoice(_info.smartInvoiceInfo);

        IWrappedInvoice(_info.invoiceAddress).init(
            _info.providers[0],
            _info.providers[1],
            smartInvoiceAddress,
            _info.splitFactor
        );

        uint256 invoiceId = invoiceCount;
        _invoices[invoiceId] = _info.invoiceAddress;
        invoiceCount = invoiceCount + 1;

        emit LogNewWrappedInvoice(invoiceId, _info.invoiceAddress);
    }

    function _newClone() internal returns (address) {
        return Clones.clone(implementation);
    }

    struct SmartInvoiceInfo {
        address client;
        address provider;
        uint8 resolverType;
        address resolver;
        address token;
        uint256[] amounts;
        uint256 terminationTime;
        bytes32 details;
    }

    struct WrappedInvoiceInfo {
        SmartInvoiceInfo smartInvoiceInfo;
        address invoiceAddress;
        address[] providers;
        uint256 splitFactor;
    }

    function create(
        address _client,
        address[] calldata _providers,
        uint256 _splitFactor,
        uint8 _resolverType,
        address _resolver,
        address _token,
        uint256[] calldata _amounts,
        uint256 _terminationTime,
        bytes32 _details
    ) external override returns (address) {
        require(_providers.length == 2, "invalid providers");

        address invoiceAddress = _newClone();

        SmartInvoiceInfo memory smartInvoiceInfo;

        {
            smartInvoiceInfo.client = _client;
            smartInvoiceInfo.provider = invoiceAddress;
            smartInvoiceInfo.resolverType = _resolverType;
            smartInvoiceInfo.resolver = _resolver;
            smartInvoiceInfo.token = _token;
            smartInvoiceInfo.amounts = _amounts;
            smartInvoiceInfo.terminationTime = _terminationTime;
            smartInvoiceInfo.details = _details;
        }

        WrappedInvoiceInfo memory wrappedInvoiceInfo;

        {
            wrappedInvoiceInfo.smartInvoiceInfo = smartInvoiceInfo;
            wrappedInvoiceInfo.invoiceAddress = invoiceAddress;
            wrappedInvoiceInfo.providers = _providers;
            wrappedInvoiceInfo.splitFactor = _splitFactor;
        }

        _init(wrappedInvoiceInfo);

        return invoiceAddress;
    }

    function getInvoiceAddress(uint256 _index) public view returns (address) {
        return _invoices[_index];
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

interface IWrappedInvoice {
    function init(
        address _parent,
        address _child,
        address _invoice,
        uint256 _splitFactor
    ) external;

    function withdrawAll() external;

    function withdrawAll(address _token) external;

    function withdraw(uint256 _amount) external;

    function withdraw(address _token, uint256 _amount) external;

    function disperseAll(
        uint256[] calldata _amounts,
        address[] calldata _fundees
    ) external;

    function disperseAll(
        uint256[] calldata _amounts,
        address[] calldata _fundees,
        address _token
    ) external;

    function disperse(
        uint256[] calldata _amounts,
        address[] calldata _fundees,
        uint256 _amount
    ) external;

    function disperse(
        uint256[] calldata _amounts,
        address[] calldata _fundees,
        address _token,
        uint256 _amount
    ) external;

    function lock(bytes32 _details) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWrappedInvoiceFactory {
    function create(
        address _client,
        address[] calldata _providers,
        uint256 _splitFactor,
        uint8 _resolverType,
        address _resolver,
        address _token,
        uint256[] calldata _amounts,
        uint256 _terminationTime,
        bytes32 _details
    ) external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISmartInvoiceFactory {
    function create(
        address _client,
        address _provider,
        uint8 _resolverType,
        address _resolver,
        address _token,
        uint256[] calldata _amounts,
        uint256 _terminationTime,
        bytes32 _details
    ) external returns (address);

    function createDeterministic(
        address _client,
        address _provider,
        uint8 _resolverType,
        address _resolver,
        address _token,
        uint256[] calldata _amounts,
        uint256 _terminationTime,
        bytes32 _details,
        bytes32 _salt
    ) external returns (address);

    function predictDeterministicAddress(bytes32 _salt)
        external
        returns (address);
}

