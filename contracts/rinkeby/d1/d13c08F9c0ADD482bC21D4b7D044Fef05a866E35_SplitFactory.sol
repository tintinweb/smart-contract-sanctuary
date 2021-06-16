// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import {SplitProxy} from "./SplitProxy.sol";
// import "hardhat/console.sol";

/**
 * @title SplitFactory
 * @author MirrorXYZ
 */
contract SplitFactory {
    //======== Immutable storage =========

    address public immutable splitter;
    address public immutable wethAddress;

    //======== Mutable storage =========

    // Gets set within the block, and then deleted.
    bytes32 public merkleRoot;

    //======== Constructor =========

    constructor(address splitter_, address wethAddress_) {
        splitter = splitter_;
        wethAddress = wethAddress_;
    }

    //======== Deploy function =========

    function createSplit(bytes32 merkleRoot_)
        external
        returns (address splitProxy)
    {
        merkleRoot = merkleRoot_;
        splitProxy = address(
            new SplitProxy{salt: keccak256(abi.encode(merkleRoot_))}()
        );
        delete merkleRoot;
        // console.log("New Split at", splitProxy);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import {SplitStorage} from "./SplitStorage.sol";

interface ISplitFactory {
    function splitter() external returns (address);

    function wethAddress() external returns (address);

    function merkleRoot() external returns (bytes32);
}

/**
 * @title SplitProxy
 * @author MirrorXYZ
 */
contract SplitProxy is SplitStorage {
    constructor() {
        _splitter = ISplitFactory(msg.sender).splitter();
        wethAddress = ISplitFactory(msg.sender).wethAddress();
        merkleRoot = ISplitFactory(msg.sender).merkleRoot();
    }

    fallback() external payable {
        address _impl = splitter();
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

    function splitter() public view returns (address) {
        return _splitter;
    }

    // Plain ETH transfers.
    receive() external payable {
        depositedInWindow += msg.value;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

/**
 * @title SplitStorage
 * @author MirrorXYZ
 */
contract SplitStorage {
    bytes32 public merkleRoot;
    uint256 public currentWindow;
    address internal wethAddress;
    address internal _splitter;
    uint256[] public balanceForWindow;
    mapping(bytes32 => bool) internal claimed;
    uint256 internal depositedInWindow;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}