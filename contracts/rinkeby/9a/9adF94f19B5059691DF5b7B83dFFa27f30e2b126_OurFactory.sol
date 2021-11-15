// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import {OurProxy} from "./OurProxy.sol";

/**
 * @title OurFactory (originally SplitFactory)
 * @author MirrorXYZ https://github.com/mirror-xyz/splits - modified by Nick Adamson for Ourz
 *
 * @notice Modified: store OurMinter.sol address, add events, remove WETHaddress in favor of constant
 */
contract OurFactory {
    //======== Graph Protocol =========
    event ProxyCreated(
        address ourProxy,
        address proxyOwner,
        string splitRecipients
    );

    //======== Immutable storage =========
    address public immutable pylon;

    //======== Mutable storage =========
    /// @dev Gets set within the block, and then deleted.
    bytes32 public merkleRoot;

    //======== Constructor =========
    constructor(address pylon_) {
        pylon = pylon_;
    }

    //======== Deploy function =========
    function createSplit(
        bytes32 merkleRoot_,
        bytes memory data,
        string memory splitRecipients_
    ) external returns (address ourProxy) {
        merkleRoot = merkleRoot_;
        ourProxy = address(
            new OurProxy{salt: keccak256(abi.encode(merkleRoot_))}()
        );
        delete merkleRoot;

        // call setup() to set owners
        assembly {
            if eq(
                call(gas(), ourProxy, 0, add(data, 0x20), mload(data), 0, 0),
                0
            ) {
                revert(0, 0)
            }
        }

        ourProxy.call(
          abi.encodeWithSignature("setApprovalsForSplit(address)", msg.sender)
        );

        emit ProxyCreated(ourProxy, msg.sender, splitRecipients_);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import {OurStorage} from "./OurStorage.sol";

interface IOurFactory {
    function pylon() external returns (address);

    function merkleRoot() external returns (bytes32);
}

/**
 * @title OurProxy (originally SplitProxy)
 * @author MirrorXYZ https://github.com/mirror-xyz/splits - modified by Nick Adamson for Ourz
 *
 * @notice Modified: added OpenZeppelin's Ownable (modified)
 */
contract OurProxy is OurStorage {
    event ETHReceived(address indexed sender, uint256 value);

    constructor() {
        _pylon = IOurFactory(msg.sender).pylon();
        merkleRoot = IOurFactory(msg.sender).merkleRoot();
    }

    function pylon() public view returns (address) {
        return _pylon;
    }

    fallback() external payable {
        address _impl = pylon();
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
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

    // Plain ETH transfers.
    receive() external payable {
        emit ETHReceived(msg.sender, msg.value);
        depositedInWindow += msg.value;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

/**
 * @title OurStorage (originally SplitStorage)
 * @author MirrorXYZ https://github.com/mirror-xyz/splits - modified by Nick Adamson for Ourz
 *
 * @notice Modified: store addresses as constants, add _minter
 */
contract OurStorage {
    bytes32 public merkleRoot;
    uint256 public currentWindow;

    address internal _pylon;

    /// @notice RINKEBY ADDRESS
    address public constant wethAddress =
        0xc778417E063141139Fce010982780140Aa0cD5Ab;

    uint256[] public balanceForWindow;
    mapping(bytes32 => bool) internal claimed;
    uint256 internal depositedInWindow;
}

