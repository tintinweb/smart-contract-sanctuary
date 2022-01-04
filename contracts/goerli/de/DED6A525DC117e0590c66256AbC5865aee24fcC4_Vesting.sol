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
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
pragma solidity ^0.8.0;

import "@beandao/contracts/interfaces/IERC20.sol";
import "@beandao/contracts/library/Initializer.sol";
import {Multicall, IMulticall} from "@beandao/contracts/library/Multicall.sol";
import {Ownership, IERC173} from "@beandao/contracts/library/Ownership.sol";

contract Vesting is Multicall, Ownership, Initializer {
    struct VestingInfo {
        uint32 startTime;
        uint32 endTime;
        uint96 initialLocked;
        uint96 totalClaimed;
    }

    address public token;
    address public escrow;
    uint256 public allocatedSupply;
    mapping(address => mapping(address => mapping(address => VestingInfo))) public vestingInfos;

    event Claimed(address indexed to, uint256 amount);

    modifier onlyEscrow() {
        require(msg.sender == escrow);
        _;
    }

    /**
     * @notice 해당 컨트랙트를 초기화 합니다.
     * @param socialToken 해당 컨트랙트에 예치되어야 하는 토큰 주소
     * @param escrowAddr 토큰을 실제로 수여할 컨트랙트 주소
     */
    function initialize(address socialToken, address escrowAddr) external initializer {
        token = socialToken;
        escrow = escrowAddr;
        _transferOwnership(msg.sender);
    }

    function lock(
        address recruiter,
        address to,
        uint256 amount,
        address subToken,
        uint256 subAmount,
        uint32 startTime,
        uint32 endTime
    ) external onlyEscrow returns (bool success) {
        assert(IERC20(token).balanceOf(address(this)) - allocatedSupply == amount);
        allocatedSupply += amount;
        vestingInfos[recruiter][to][token] = VestingInfo({
            startTime: startTime,
            endTime: endTime,
            initialLocked: safe96(amount),
            totalClaimed: 0
        });

        if (subToken != address(0) && subAmount != 0) {
            // 부수적으로 지급할 토큰이 있는 경우
            vestingInfos[recruiter][to][subToken] = VestingInfo({
                startTime: startTime,
                endTime: endTime,
                initialLocked: safe96(subAmount),
                totalClaimed: 0
            });
        }

        success = true;
    }

    function claim(
        address recruiter,
        address to,
        address tokenAddr
    ) external {
        uint256 claimable = _vestedOf(recruiter, to, tokenAddr) - vestingInfos[recruiter][to][tokenAddr].totalClaimed;
        assert(safeTransfer(tokenAddr, to, claimable));
        allocatedSupply -= claimable;
        vestingInfos[recruiter][to][tokenAddr].totalClaimed += safe96(claimable);
        emit Claimed(to, claimable);
    }

    function claimableOf(
        address recruiter,
        address to,
        address tokenAddr
    ) public view returns (uint256 amount) {
        amount = _vestedOf(recruiter, to, tokenAddr) - vestingInfos[recruiter][to][tokenAddr].totalClaimed;
    }

    /// @notice 지정된 시간으로 부터 지금까지 할당된 총 토큰 수량
    function _vestedOf(
        address recruiter,
        address to,
        address tokenAddr
    ) internal view returns (uint256 amount) {
        uint32 start = vestingInfos[recruiter][to][tokenAddr].startTime;
        uint32 end = vestingInfos[recruiter][to][tokenAddr].endTime;
        uint256 locked = vestingInfos[recruiter][to][tokenAddr].initialLocked;
        uint256 least = ((locked * (block.timestamp - start)) / (end - start));
        amount = block.timestamp < start ? 0 : least > locked ? locked : least;
    }

    function safe96(uint256 value) internal pure returns (uint96) {
        return value <= type(uint96).max ? uint96(value) : 0;
    }

    /// @notice Modified from Gnosis
    /// (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
    function safeTransfer(
        address tokenAddr,
        address to,
        uint256 amount
    ) internal returns (bool success) {
        bool callStatus;

        assembly {
            let freePointer := mload(0x40)
            mstore(freePointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freePointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(add(freePointer, 36), amount)

            callStatus := call(gas(), tokenAddr, 0, freePointer, 68, 0, 0)

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