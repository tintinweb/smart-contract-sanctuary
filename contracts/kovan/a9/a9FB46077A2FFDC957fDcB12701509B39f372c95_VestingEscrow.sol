/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

/**
 * @title ERC-173 Contract Ownership Standard
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-173.md
 * Note: the ERC-165 identifier for this interface is 0x7f5828d0
 */
interface IERC173 {
    /**
     * @dev This emits when ownership of a contract changes.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @notice Get the address of the owner
     * @return The address of the owner.
     */
    function owner() external view returns (address);

    /**
     * @notice Set the address of the new owner of the contract
     * @param newOwner The address of the new owner of the contract
     */
    function transferOwnership(address newOwner) external;
}

/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function balanceOf(address target) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);
}

/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

interface IERC2612 {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

interface IMulticall {
    function multicall(bytes[] calldata callData) external returns (bytes[] memory returnData);
}

/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

library Address {
    function isContract(address target) internal view returns (bool result) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            result := gt(extcodesize(target), 0)
        }
    }
}

/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "./Address.sol";

abstract contract Initializer {
    using Address for address;

    bool private _initialized;

    modifier initializer() {
        require(!_initialized || !address(this).isContract(), "Initializer/Already Initialized");
        _initialized = true;
        _;
    }
}

/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../interfaces/IMulticall.sol";

/**
 * @title Multicall
 * @author yoonsung.eth
 * @notice 컨트랙트가 가지고 있는 트랜잭션을 순서대로 실행시킬 수 있음.
 */
abstract contract Multicall is IMulticall {
    function multicall(bytes[] calldata callData) external override returns (bytes[] memory returnData) {
        returnData = new bytes[](callData.length);
        for (uint256 i = 0; i < callData.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(callData[i]);
            // Next 5 lines from https://ethereum.stackexchange.com/a/83577
            if (!success) {
                // revert called without a message
                if (result.length < 68) revert();
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            returnData[i] = result;
        }
    }
}

/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../interfaces/IERC173.sol";

/**
 * @title Ownership
 * @author yoonsung.eth
 * @notice 단일 Ownership을 가질 수 있도록 도와주는 추상 컨트랙트
 * @dev constructor 기반 컨트랙트에서는 생성 시점에 owner가 msg.sender로 지정되며,
 *      Proxy로 작동되는 컨트랙트의 경우 `__transferOwnership(address)`를 명시적으로 호출하여 owner를 지정하여야 한다.
 */
abstract contract Ownership is IERC173 {
    address public override owner;

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownership/Not-Authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function transferOwnership(address newOwner) external virtual override onlyOwner {
        require(newOwner != address(0), "Ownership/Not-Allowed-Zero");
        _transferOwnership(newOwner);
    }

    function resignOwnership() external virtual onlyOwner {
        delete owner;
        emit OwnershipTransferred(msg.sender, address(0));
    }

    function _transferOwnership(address newOwner) internal {
        address prev = owner;
        owner = newOwner;
        emit OwnershipTransferred(prev, newOwner);
    }
}

/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */
pragma solidity ^0.8.0;

import "@beandao/contracts/interfaces/IERC20.sol";
import "@beandao/contracts/interfaces/IERC2612.sol";
import "@beandao/contracts/interfaces/IERC165.sol";
import {Initializer} from "@beandao/contracts/library/Initializer.sol";
import {Ownership, IERC173} from "@beandao/contracts/library/Ownership.sol";
import {Multicall, IMulticall} from "@beandao/contracts/library/Multicall.sol";

contract VestingEscrow is Multicall, Ownership, Initializer, IERC165 {
    struct LockParam {
        address recipient;
        uint128 amount;
        uint128 startAt;
        uint128 endAt;
    }

    struct Vest {
        uint128 startTime;
        uint128 endTime;
        uint128 initialLocked;
        uint128 totalClaimed;
    }

    /// @notice 배포할 토큰
    IERC20 public token;
    /// @notice 배포가 결정되지 않은 토큰 수량
    uint256 public unallocatedSupply;
    /// @notice 배포가 결정된 토큰 수량
    uint256 public allocatedSupply;

    mapping(address => Vest) public vests;

    event Funded(uint256 amount);
    event Locked(address indexed recipient, uint256 amount, uint256 startTime);
    event Claimed(address indexed recipient, uint256 amount);

    function initialize(address tokenAddr, LockParam[] calldata params) external initializer {
        token = IERC20(tokenAddr);
        unchecked {
            for (uint256 i = 0; i < params.length; i++) {
                _lock(params[i]);
            }
        }
        _transferOwnership(msg.sender);
    }

    /**
     * @notice 토큰을 필요한 수량만큼 해당 컨트랙트로 이관하는 함수
     */
    function fund(uint256 amount) external onlyOwner {
        assert(safeTransferFrom(token, msg.sender, address(this), amount));
        unallocatedSupply += amount;
        unchecked {
            if (allocatedSupply > 0) {
                allocatedSupply -= amount;
            }
        }
        emit Funded(amount);
    }

    /**
     * @notice 토큰을 필요한 수량만큼 해당 컨트랙트로 이관하는 함수, 다만 Approve는 서명으로 수행함
     */
    function fund(
        uint256 amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external onlyOwner {
        IERC2612(address(token)).permit(msg.sender, address(this), amount, type(uint256).max, v, r, s);
        assert(safeTransferFrom(token, msg.sender, address(this), amount));
        unallocatedSupply += amount;
        unchecked {
            if (allocatedSupply > 0) {
                allocatedSupply -= amount;
            }
        }
        emit Funded(amount);
    }

    /**
     * @notice 개별 주소에 베스팅을 지정하는 함수
     * @param recipient 베스팅이 지정될 주소
     * @param amount 베스팅 수량
     * @param startAt 베스팅 시작 시점, Unix time을 이용
     * @param endAt 베스팅 종료 시점, Unix time을 이용
     */
    function lock(
        address recipient,
        uint128 amount,
        uint128 startAt,
        uint128 endAt
    ) external onlyOwner {
        require(recipient != address(0), "VestingEscrow/Now-Allowed-For-Zero");
        require(unallocatedSupply >= amount, "VestingEscrow/Not-Enough-balance");
        require(vests[recipient].startTime == 0, "VestingEscrow/Already-Registred");
        require(startAt >= block.timestamp, "VestingEscrow/Forwarded-start");
        require(endAt > startAt, "VestingEscrow/Bigger-than-end");
        assert(allocatedSupply == 0);

        unchecked {
            unallocatedSupply -= amount;
        }
        vests[recipient] = Vest({startTime: startAt, endTime: endAt, initialLocked: amount, totalClaimed: 0});
        emit Locked(recipient, amount, startAt);
    }

    function claim(address recipient) external {
        uint256 claimable = _vestedOf(recipient) - vests[recipient].totalClaimed;
        assert(safeTransfer(token, recipient, claimable));
        unchecked {
            vests[recipient].totalClaimed += uint128(claimable);
        }
        emit Claimed(recipient, claimable);
    }

    function decreaseLockedOf(address recipient, uint128 amount) external onlyOwner {
        // 아직 잠겨있는 물량보다, 줄여야 할 물량이 많아야 함
        require(_lockedOf(recipient) >= amount, "Not Enough");
        this.claim(recipient);
        unchecked {
            vests[recipient].initialLocked -= amount;
        }
        unallocatedSupply += amount;
    }

    function claimableOf(address recipient) public view returns (uint256 amount) {
        amount = _vestedOf(recipient) - vests[recipient].totalClaimed;
    }

    /// @notice 지정된 시간으로 부터 지금까지 할당된 총 토큰 수량
    function _vestedOf(address recipient) internal view returns (uint256 amount) {
        uint256 start = vests[recipient].startTime;
        uint256 end = vests[recipient].endTime;
        uint256 locked = vests[recipient].initialLocked;
        unchecked {
            uint256 least = ((locked * (block.timestamp - start)) / (end - start));
            amount = block.timestamp < start ? 0 : least > locked ? locked : least;
        }
    }

    /// @notice 지정된 시간으로 부터 지금까지 잠금되어 남아있는 총 토큰 수량
    function _lockedOf(address recipient) internal view returns (uint256 amount) {
        uint256 start = vests[recipient].startTime;
        uint256 end = vests[recipient].endTime;
        uint256 locked = vests[recipient].initialLocked;
        unchecked {
            uint256 least = ((locked * (block.timestamp - start)) / (end - start));
            amount = block.timestamp < start ? locked : locked - least;
        }
    }

    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return
            interfaceID == type(IERC165).interfaceId ||
            interfaceID == type(IERC173).interfaceId ||
            interfaceID == type(IMulticall).interfaceId;
    }

    function _lock(LockParam calldata param) internal {
        allocatedSupply += param.amount;
        vests[param.recipient] = Vest({
            startTime: param.startAt,
            endTime: param.endAt,
            initialLocked: param.amount,
            totalClaimed: 0
        });
        emit Locked(param.recipient, param.amount, param.startAt);
    }

    /// @notice Modified from Gnosis
    /// (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
    function safeTransferFrom(
        IERC20 tokenAddr,
        address from,
        address to,
        uint256 amount
    ) internal returns (bool success) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freePointer := mload(0x40)
            mstore(freePointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freePointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(add(freePointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(add(freePointer, 68), amount)

            let callStatus := call(gas(), tokenAddr, 0, freePointer, 100, 0, 0)

            let returnDataSize := returndatasize()
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }
            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
        }
    }

    function safeTransfer(
        IERC20 tokenAddr,
        address to,
        uint256 amount
    ) internal returns (bool success) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freePointer := mload(0x40)
            mstore(freePointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freePointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(add(freePointer, 36), amount)

            let callStatus := call(gas(), tokenAddr, 0, freePointer, 68, 0, 0)

            let returnDataSize := returndatasize()
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }
            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
        }
    }
}