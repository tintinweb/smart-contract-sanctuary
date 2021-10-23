// SPDX-License-Identifier: GPL-3.0-or-later

/**   ____________________________________________________________________________________        
     ___________/\/\/\/\________/\/\____/\/\______/\/\/\/\/\________/\/\/\/\/\/\_________
    _________/\/\____/\/\______/\/\____/\/\______/\/\____/\/\____________/\/\___________ 
   _________/\/\____/\/\______/\/\____/\/\______/\/\/\/\/\____________/\/\_____________  
  _________/\/\____/\/\______/\/\____/\/\______/\/\__/\/\__________/\/\_______________   
 ___________/\/\/\/\__________/\/\/\/\________/\/\____/\/\______/\/\/\/\/\/\_________    
____________________________________________________________________________________ */

pragma solidity 0.8.4;

import {OurProxy} from "./OurProxy.sol";

/**
 * @title OurFactory
 * @author Nick A.
 * https://github.com/ourz-network/our-contracts
 *
 * These contracts enable creators, builders, & collaborators of all kinds
 * to receive royalties for their collective work, forever.
 *
 * Thank you,
 * @author Mirror       @title Splits   https://github.com/mirror-xyz/splits
 * @author Gnosis       @title Safe     https://github.com/gnosis/safe-contracts
 * @author OpenZeppelin                 https://github.com/OpenZeppelin/openzeppelin-contracts
 * @author Zora                         https://github.com/ourzora
 */

contract OurFactory {
    //======== Immutable storage =========
    address public immutable pylon;

    //======== Mutable storage =========
    /// @dev Gets set within the block, and then deleted.
    bytes32 public merkleRoot;

    //======== Subgraph =========
    event SplitCreated(
        address ourProxy,
        address proxyCreator,
        string splitRecipients,
        string nickname
    );

    //======== Constructor =========
    constructor(address pylon_) {
        pylon = pylon_;
    }

    //======== Deploy function =========
    function createSplit(
        bytes32 merkleRoot_,
        bytes memory data,
        string calldata splitRecipients_,
        string calldata nickname_
    ) external returns (address ourProxy) {
        merkleRoot = merkleRoot_;
        ourProxy = address(
            new OurProxy{salt: keccak256(abi.encode(merkleRoot_))}()
        );
        delete merkleRoot;

        emit SplitCreated(ourProxy, msg.sender, splitRecipients_, nickname_);

        // call setup() to set Owners of Split
        // solhint-disable-next-line no-inline-assembly
        assembly {
            if eq(
                call(gas(), ourProxy, 0, add(data, 0x20), mload(data), 0, 0),
                0
            ) {
                revert(0, 0)
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

/**   ____________________________________________________________________________________        
     ___________/\/\/\/\________/\/\____/\/\______/\/\/\/\/\________/\/\/\/\/\/\_________
    _________/\/\____/\/\______/\/\____/\/\______/\/\____/\/\____________/\/\___________ 
   _________/\/\____/\/\______/\/\____/\/\______/\/\/\/\/\____________/\/\_____________  
  _________/\/\____/\/\______/\/\____/\/\______/\/\__/\/\__________/\/\_______________   
 ___________/\/\/\/\__________/\/\/\/\________/\/\____/\/\______/\/\/\/\/\/\_________    
____________________________________________________________________________________ */

pragma solidity 0.8.4;

import {OurStorage} from "./OurStorage.sol";

interface IOurFactory {
    function pylon() external returns (address);

    function merkleRoot() external returns (bytes32);
}

/**
 * @title OurProxy
 * @author Nick A.
 * https://github.com/ourz-network/our-contracts
 *
 * These contracts enable creators, builders, & collaborators of all kinds
 * to receive royalties for their collective work, forever.
 *
 * Thank you,
 * @author Mirror       @title Splits   https://github.com/mirror-xyz/splits
 * @author Gnosis       @title Safe     https://github.com/gnosis/safe-contracts
 * @author OpenZeppelin                 https://github.com/OpenZeppelin/openzeppelin-contracts
 * @author Zora                         https://github.com/ourzora
 */

contract OurProxy is OurStorage {
    constructor() {
        _pylon = IOurFactory(msg.sender).pylon();
        merkleRoot = IOurFactory(msg.sender).merkleRoot();
    }

    // solhint-disable-next-line no-complex-fallback
    fallback() external payable {
        address impl = pylon();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), impl, ptr, calldatasize(), 0, 0)
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

    function pylon() public view returns (address) {
        return _pylon;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

/**
 * @title OurStorage
 * @author Nick A.
 * https://github.com/ourz-network/our-contracts
 *
 * These contracts enable creators, builders, & collaborators of all kinds
 * to receive royalties for their collective work, forever.
 *
 * Thank you,
 * @author Mirror       @title Splits   https://github.com/mirror-xyz/splits
 * @author Gnosis       @title Safe     https://github.com/gnosis/safe-contracts
 * @author OpenZeppelin                 https://github.com/OpenZeppelin/openzeppelin-contracts
 * @author Zora                         https://github.com/ourzora
 */

contract OurStorage {
    bytes32 public merkleRoot;
    uint256 public currentWindow;

    address internal _pylon;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint256[] public balanceForWindow;
    mapping(bytes32 => bool) internal _claimed;
    uint256 internal _depositedInWindow;
}