// SPDX-License-Identifier: BUSL-1.1
// For further clarification please see https://license.premia.legal

pragma solidity ^0.8.0;

import {ProxyUpgradeableOwnable} from "../ProxyUpgradeableOwnable.sol";
import {PremiaMiningStorage} from "./PremiaMiningStorage.sol";

contract PremiaMiningProxy is ProxyUpgradeableOwnable {
    constructor(address implementation, uint256 premiaPerBlock)
        ProxyUpgradeableOwnable(implementation)
    {
        PremiaMiningStorage.layout().premiaPerBlock = premiaPerBlock;
    }
}

// SPDX-License-Identifier: BUSL-1.1
// For further clarification please see https://license.premia.legal

pragma solidity ^0.8.0;

import {Proxy} from "@solidstate/contracts/proxy/Proxy.sol";
import {SafeOwnable, OwnableStorage} from "@solidstate/contracts/access/SafeOwnable.sol";
import {ProxyUpgradeableOwnableStorage} from "./ProxyUpgradeableOwnableStorage.sol";

contract ProxyUpgradeableOwnable is Proxy, SafeOwnable {
    using ProxyUpgradeableOwnableStorage for ProxyUpgradeableOwnableStorage.Layout;
    using OwnableStorage for OwnableStorage.Layout;

    constructor(address implementation) {
        OwnableStorage.layout().setOwner(msg.sender);
        ProxyUpgradeableOwnableStorage.layout().implementation = implementation;
    }

    receive() external payable {}

    /**
     * @inheritdoc Proxy
     */
    function _getImplementation() internal view override returns (address) {
        return ProxyUpgradeableOwnableStorage.layout().implementation;
    }

    /**
     * @notice get address of implementation contract
     * @return implementation address
     */
    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    /**
     * @notice set address of implementation contract
     * @param implementation address of the new implementation
     */
    function setImplementation(address implementation) external onlyOwner {
        ProxyUpgradeableOwnableStorage.layout().implementation = implementation;
    }
}

// SPDX-License-Identifier: BUSL-1.1
// For further clarification please see https://license.premia.legal

pragma solidity ^0.8.0;

library PremiaMiningStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256("premia.contracts.storage.PremiaMining");

    // Info of each pool.
    struct PoolInfo {
        uint256 allocPoint; // How many allocation points assigned to this pool. PREMIA to distribute per block.
        uint256 lastRewardBlock; // Last block number that PREMIA distribution occurs.
        uint256 accPremiaPerShare; // Accumulated PREMIA per share, times 1e12. See below.
    }

    // Info of each user.
    struct UserInfo {
        uint256 reward; // Total allocated unclaimed reward
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of PREMIA
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accPremiaPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accPremiaPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    struct Layout {
        // Total PREMIA left to distribute
        uint256 premiaAvailable;
        // Amount of premia per block distributed
        uint256 premiaPerBlock;
        // pool -> isCallPool -> PoolInfo
        mapping(address => mapping(bool => PoolInfo)) poolInfo;
        // pool -> isCallPool -> user -> UserInfo
        mapping(address => mapping(bool => mapping(address => UserInfo))) userInfo;
        // Total allocation points. Must be the sum of all allocation points in all pools.
        uint256 totalAllocPoint;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { AddressUtils } from '../utils/AddressUtils.sol';

/**
 * @title Base proxy contract
 */
abstract contract Proxy {
    using AddressUtils for address;

    /**
     * @notice delegate all calls to implementation contract
     * @dev reverts if implementation address contains no code, for compatibility with metamorphic contracts
     * @dev memory location in use by assembly may be unsafe in other contexts
     */
    fallback() external payable virtual {
        address implementation = _getImplementation();

        require(
            implementation.isContract(),
            'Proxy: implementation must be contract'
        );

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @notice get logic implementation address
     * @return implementation address
     */
    function _getImplementation() internal virtual returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Ownable, OwnableStorage } from './Ownable.sol';
import { SafeOwnableInternal } from './SafeOwnableInternal.sol';
import { SafeOwnableStorage } from './SafeOwnableStorage.sol';

/**
 * @title Ownership access control based on ERC173 with ownership transfer safety check
 */
abstract contract SafeOwnable is Ownable, SafeOwnableInternal {
    using OwnableStorage for OwnableStorage.Layout;
    using SafeOwnableStorage for SafeOwnableStorage.Layout;

    function nomineeOwner() public view virtual returns (address) {
        return SafeOwnableStorage.layout().nomineeOwner;
    }

    /**
     * @inheritdoc Ownable
     * @dev ownership transfer must be accepted by beneficiary before transfer is complete
     */
    function transferOwnership(address account)
        public
        virtual
        override
        onlyOwner
    {
        SafeOwnableStorage.layout().setNomineeOwner(account);
    }

    /**
     * @notice accept transfer of contract ownership
     */
    function acceptOwnership() public virtual onlyNomineeOwner {
        OwnableStorage.Layout storage l = OwnableStorage.layout();
        emit OwnershipTransferred(l.owner, msg.sender);
        l.setOwner(msg.sender);
        SafeOwnableStorage.layout().setNomineeOwner(address(0));
    }
}

// SPDX-License-Identifier: BUSL-1.1
// For further clarification please see https://license.premia.legal

pragma solidity ^0.8.0;

library ProxyUpgradeableOwnableStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256("premia.contracts.storage.ProxyUpgradeableOwnable");

    struct Layout {
        address implementation;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library AddressUtils {
    function toString(address account) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(account)));
        bytes memory alphabet = '0123456789abcdef';
        bytes memory chars = new bytes(42);

        chars[0] = '0';
        chars[1] = 'x';

        for (uint256 i = 0; i < 20; i++) {
            chars[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            chars[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }

        return string(chars);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{ value: amount }('');
        require(success, 'AddressUtils: failed to send value');
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCall(target, data, 'AddressUtils: failed low-level call');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                'AddressUtils: failed low-level call with value'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            'AddressUtils: insufficient balance for call'
        );
        return _functionCallWithValue(target, data, value, error);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        require(
            isContract(target),
            'AddressUtils: function call to non-contract'
        );

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC173 } from './IERC173.sol';
import { OwnableInternal } from './OwnableInternal.sol';
import { OwnableStorage } from './OwnableStorage.sol';

/**
 * @title Ownership access control based on ERC173
 */
abstract contract Ownable is IERC173, OwnableInternal {
    using OwnableStorage for OwnableStorage.Layout;

    /**
     * @inheritdoc IERC173
     */
    function owner() public view virtual override returns (address) {
        return OwnableStorage.layout().owner;
    }

    /**
     * @inheritdoc IERC173
     */
    function transferOwnership(address account)
        public
        virtual
        override
        onlyOwner
    {
        OwnableStorage.layout().setOwner(account);
        emit OwnershipTransferred(msg.sender, account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { SafeOwnableStorage } from './SafeOwnableStorage.sol';

abstract contract SafeOwnableInternal {
    using SafeOwnableStorage for SafeOwnableStorage.Layout;

    modifier onlyNomineeOwner() {
        require(
            msg.sender == SafeOwnableStorage.layout().nomineeOwner,
            'SafeOwnable: sender must be nominee owner'
        );
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SafeOwnableStorage {
    struct Layout {
        address nomineeOwner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.SafeOwnable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setNomineeOwner(Layout storage l, address nomineeOwner) internal {
        l.nomineeOwner = nomineeOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Contract ownership standard interface
 * @dev see https://eips.ethereum.org/EIPS/eip-173
 */
interface IERC173 {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @notice get the ERC173 contract owner
     * @return conract owner
     */
    function owner() external view returns (address);

    /**
     * @notice transfer contract ownership to new account
     * @param account address of new owner
     */
    function transferOwnership(address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { OwnableStorage } from './OwnableStorage.sol';

abstract contract OwnableInternal {
    using OwnableStorage for OwnableStorage.Layout;

    modifier onlyOwner() {
        require(
            msg.sender == OwnableStorage.layout().owner,
            'Ownable: sender must be owner'
        );
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Ownable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setOwner(Layout storage l, address owner) internal {
        l.owner = owner;
    }
}