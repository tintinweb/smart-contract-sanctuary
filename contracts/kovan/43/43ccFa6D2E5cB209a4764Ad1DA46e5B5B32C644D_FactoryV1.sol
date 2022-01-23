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

/**
 * @title BeaconDeployer
 * @author yoonsung.eth
 * @notice library that deploy Beacon contract.
 */
library BeaconDeployer {
    function deploy(address implementation) internal returns (address result) {
        bytes memory code = abi.encodePacked(
            hex"606161002960003933600081816002015260310152602080380360803960805160005560616000f3fe337f00000000000000000000000000000000000000000000000000000000000000001415602e57600035600055005b337f00000000000000000000000000000000000000000000000000000000000000001460605760005460005260206000f35b",
            abi.encode(implementation)
        );

        // solhint-disable-next-line no-inline-assembly
        assembly {
            result := create(0, add(code, 0x20), mload(code))

            // pass along failure message from failed contract deployment and revert.
            if iszero(extcodesize(result)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }
}

/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

/**
 * @title BeaconMaker
 * @author yoonsung.eth
 * @notice Beacon Minimal Proxy를 배포하는 기능을 가진 Maker Dummy
 * @dev template에는 단 한번만 호출 가능한 initialize 함수가 필요하며, 이는 필수적으로 호출되어 과정이 생략되어야 함.
 */
contract BeaconMaker {
    /**
     * @param beacon call 했을 경우, 주소가 반환되어야 하는 컨트랙트
     */
    constructor(address beacon) payable {
        // Beacon Address
        bytes20 targetBytes = bytes20(beacon);
        // place Beacon Proxy code in memory.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d3d3d3d3d730000000000000000000000000000000000000000000000000000)
            mstore(add(clone, 0x6), targetBytes)
            mstore(add(clone, 0x1a), 0x5afa3d82803e368260203750808036602082515af43d82803e903d91603a57fd)
            mstore(add(clone, 0x3a), 0x5bf3000000000000000000000000000000000000000000000000000000000000)
            // return Beacon Minimal Proxy code to write it to spawned contract runtime.
            return(add(0x00, clone), 0x3c) // Beacon Minimal Proxy runtime code, length
        }
    }
}

/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

/**
 * @title BeaconMakerWithCall
 * @author yoonsung.eth
 * @notice Beacon Minimal Proxy를 배포하는 기능을 가진 Maker Dummy
 * @dev template에는 단 한번만 호출 가능한 initialize 함수가 필요하며, 이는 필수적으로 호출되어 과정이 생략되어야 함.
 */
contract BeaconMakerWithCall {
    /**
     * @param beacon call 했을 경우, 주소가 반환되어야 함
     * @param initializationCalldata template로 배포할 때 초기화 할 함수
     */
    constructor(address beacon, bytes memory initializationCalldata) payable {
        (, bytes memory returnData) = beacon.staticcall("");
        address template = abi.decode(returnData, (address));
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = template.delegatecall(initializationCalldata);
        if (!success) {
            // pass along failure message from delegatecall and revert.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        // Beacon Address
        bytes20 targetBytes = bytes20(beacon);
        // place Beacon Proxy code in memory.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d3d3d3d3d730000000000000000000000000000000000000000000000000000)
            mstore(add(clone, 0x6), targetBytes)
            mstore(add(clone, 0x1a), 0x5afa3d82803e368260203750808036602082515af43d82803e903d91603a57fd)
            mstore(add(clone, 0x3a), 0x5bf3000000000000000000000000000000000000000000000000000000000000)
            // return Beacon Minimal Proxy code to write it to spawned contract runtime.
            return(add(0x00, clone), 0x3c) // Beacon Minimal Proxy runtime code, length
        }
    }
}

/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "./BeaconMaker.sol";
import "./BeaconMakerWithCall.sol";

/**
 * @title BeaconProxyDeployer
 * @author yoonsung.eth
 * @notice Beacon Minimal Proxy를 배포하는 기능을 가진 라이브러리
 */
library BeaconProxyDeployer {
    function deploy(address beacon, bytes memory initializationCalldata) internal returns (address result) {
        bytes memory createCode = creation(beacon, initializationCalldata);

        (bytes32 salt, ) = getSaltAndTarget(createCode);

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let encoded_data := add(0x20, createCode) // load initialization code.
            let encoded_size := mload(createCode) // load the init code's length.
            result := create2(
                // call `CREATE2` w/ 4 arguments.
                0, // forward any supplied endowment.
                encoded_data, // pass in initialization code.
                encoded_size, // pass in init code's length.
                salt // pass in the salt value.
            )

            // pass along failure message from failed contract deployment and revert.
            if iszero(extcodesize(result)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function deploy(
        string memory seed,
        address beacon,
        bytes memory initializationCalldata
    ) internal returns (address result) {
        bytes memory createCode = creation(beacon, initializationCalldata);

        bytes32 salt = keccak256(abi.encodePacked(msg.sender, seed));

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let encoded_data := add(0x20, createCode) // load initialization code.
            let encoded_size := mload(createCode) // load the init code's length.
            result := create2(
                // call `CREATE2` w/ 4 arguments.
                0, // forward any supplied endowment.
                encoded_data, // pass in initialization code.
                encoded_size, // pass in init code's length.
                salt // pass in the salt value.
            )

            // pass along failure message from failed contract deployment and revert.
            if iszero(extcodesize(result)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function calculateAddress(address template, bytes memory initializationCalldata)
        internal
        view
        returns (address addr)
    {
        bytes memory createCode = creation(template, initializationCalldata);

        (, addr) = getSaltAndTarget(createCode);
    }

    function calculateAddress(
        string memory seed,
        address template,
        bytes memory initializationCalldata
    ) internal view returns (address addr) {
        bytes memory createCode = creation(template, initializationCalldata);

        addr = getTargetFromSeed(createCode, seed);
    }

    function isBeacon(address beaconAddr, address target) internal view returns (bool result) {
        bytes20 beaconAddrBytes = bytes20(beaconAddr);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d3d3d3d3d730000000000000000000000000000000000000000000000000000)
            mstore(add(clone, 0x6), beaconAddrBytes)
            mstore(add(clone, 0x1a), 0x5afa3d82803e368260203750808036602082515af43d82803e903d91603a57fd)
            mstore(add(clone, 0x3a), 0x5bf3000000000000000000000000000000000000000000000000000000000000)

            let other := add(clone, 0x40)
            extcodecopy(target, other, 0, 0x3c)
            result := eq(mload(clone), mload(other))
        }
    }

    function getSaltAndTarget(bytes memory initCode) internal view returns (bytes32 salt, address target) {
        // get the keccak256 hash of the init code for address derivation.
        bytes32 initCodeHash = keccak256(initCode);

        // set the initial nonce to be provided when constructing the salt.
        uint256 nonce = 0;

        // declare variable for code size of derived address.
        bool exist;

        while (true) {
            // derive `CREATE2` salt using `msg.sender` and nonce.
            salt = keccak256(abi.encodePacked(msg.sender, nonce));

            target = address( // derive the target deployment address.
                uint160( // downcast to match the address type.
                    uint256( // cast to uint to truncate upper digits.
                        keccak256( // compute CREATE2 hash using 4 inputs.
                            abi.encodePacked( // pack all inputs to the hash together.
                                bytes1(0xff), // pass in the control character.
                                address(this), // pass in the address of this contract.
                                salt, // pass in the salt from above.
                                initCodeHash // pass in hash of contract creation code.
                            )
                        )
                    )
                )
            );

            // determine if a contract is already deployed to the target address.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                exist := gt(extcodesize(target), 0)
            }

            // exit the loop if no contract is deployed to the target address.
            if (!exist) {
                break;
            }

            // otherwise, increment the nonce and derive a new salt.
            nonce++;
        }
    }

    function getTargetFromSeed(bytes memory initCode, string memory seed) internal view returns (address target) {
        // get the keccak256 hash of the init code for address derivation.
        bytes32 initCodeHash = keccak256(initCode);

        bytes32 salt = keccak256(abi.encodePacked(msg.sender, seed));

        target = address( // derive the target deployment address.
            uint160( // downcast to match the address type.
                uint256( // cast to uint to truncate upper digits.
                    keccak256( // compute CREATE2 hash using 4 inputs.
                        abi.encodePacked( // pack all inputs to the hash together.
                            bytes1(0xff), // pass in the control character.
                            address(this), // pass in the address of this contract.
                            salt, // pass in the salt from above.
                            initCodeHash // pass in hash of contract creation code.
                        )
                    )
                )
            )
        );
    }

    function creation(address addr, bytes memory initializationCalldata)
        private
        pure
        returns (bytes memory createCode)
    {
        createCode = initializationCalldata.length > 0
            ? abi.encodePacked(
                type(BeaconMakerWithCall).creationCode,
                abi.encode(address(addr), initializationCalldata)
            )
            : abi.encodePacked(type(BeaconMaker).creationCode, abi.encode(address(addr)));
    }
}

/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

/**
 * @title MinimalMaker
 * @author yoonsung.eth
 * @notice Minimal Proxy를 배포하는 기능을 가진 Maker Dummy
 * @dev template에는 단 한번만 호출 가능한 initialize 함수가 필요하며, 이는 필수적으로 호출되어 과정이 생략되어야 함.
 */
contract MinimalMaker {
    constructor(address template) payable {
        // Template Address
        bytes20 targetBytes = bytes20(template);
        // place Minimal Proxy eip-1167 code in memory.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
            mstore(add(clone, 0xa), targetBytes)
            mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            // return eip-1167 code to write it to spawned contract runtime.
            return(add(0x00, clone), 0x2d) // eip-1167 runtime code, length
        }
    }
}

/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

/**
 * @title MinimalMakerWithCall
 * @author yoonsung.eth
 * @notice Minimal Proxy를 배포하는 기능을 가진 Maker Dummy
 * @dev template에는 단 한번만 호출 가능한 initialize 함수가 필요하며, 이는 필수적으로 호출되어 과정이 생략되어야 함.
 */
contract MinimalMakerWithCall {
    constructor(address template, bytes memory initializationCalldata) payable {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = template.delegatecall(initializationCalldata);
        if (!success) {
            // pass along failure message from delegatecall and revert.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        // Template Address
        bytes20 targetBytes = bytes20(template);
        // place Minimal Proxy eip-1167 code in memory.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
            mstore(add(clone, 0xa), targetBytes)
            mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            // return eip-1167 code to write it to spawned contract runtime.
            return(add(0x00, clone), 0x2d) // eip-1167 runtime code, length
        }
    }
}

/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "./MinimalMaker.sol";
import "./MinimalMakerWithCall.sol";

/**
 * @title MinimalProxyDeployer
 * @author yoonsung.eth
 * @notice Minimal Proxy를 배포하는 기능을 가진 라이브러리
 */
library MinimalProxyDeployer {
    function deploy(address template, bytes memory initializationCalldata) internal returns (address result) {
        bytes memory createCode = creation(template, initializationCalldata);

        (bytes32 salt, ) = getSaltAndTarget(createCode);

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let encoded_data := add(0x20, createCode) // load initialization code.
            let encoded_size := mload(createCode) // load the init code's length.
            result := create2(
                // call `CREATE2` w/ 4 arguments.
                0, // forward any supplied endowment.
                encoded_data, // pass in initialization code.
                encoded_size, // pass in init code's length.
                salt // pass in the salt value.
            )

            // pass along failure message from failed contract deployment and revert.
            if iszero(extcodesize(result)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function deploy(
        string memory seed,
        address template,
        bytes memory initializationCalldata
    ) internal returns (address result) {
        bytes memory createCode = creation(template, initializationCalldata);

        bytes32 salt = keccak256(abi.encodePacked(msg.sender, seed));

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let encoded_data := add(0x20, createCode) // load initialization code.
            let encoded_size := mload(createCode) // load the init code's length.
            result := create2(
                // call `CREATE2` w/ 4 arguments.
                0, // forward any supplied endowment.
                encoded_data, // pass in initialization code.
                encoded_size, // pass in init code's length.
                salt // pass in the salt value.
            )

            // pass along failure message from failed contract deployment and revert.
            if iszero(extcodesize(result)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function calculateAddress(address template, bytes memory initializationCalldata)
        internal
        view
        returns (address addr)
    {
        bytes memory createCode = creation(template, initializationCalldata);

        (, addr) = getSaltAndTarget(createCode);
    }

    function calculateAddress(
        string memory seed,
        address template,
        bytes memory initializationCalldata
    ) internal view returns (address addr) {
        bytes memory createCode = creation(template, initializationCalldata);

        addr = getTargetFromSeed(createCode, seed);
    }

    function isMinimal(address templateAddr, address target) internal view returns (bool result) {
        bytes20 templateAddrBytes = bytes20(templateAddr);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
            mstore(add(clone, 0xa), templateAddrBytes)
            mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

            let other := add(clone, 0x40)
            extcodecopy(target, other, 0, 0x2d)
            result := eq(mload(clone), mload(other))
        }
    }

    function getSaltAndTarget(bytes memory initCode) internal view returns (bytes32 salt, address target) {
        // get the keccak256 hash of the init code for address derivation.
        bytes32 initCodeHash = keccak256(initCode);

        // set the initial nonce to be provided when constructing the salt.
        uint256 nonce = 0;

        // declare variable for code size of derived address.
        bool exist;

        while (true) {
            // derive `CREATE2` salt using `msg.sender` and nonce.
            salt = keccak256(abi.encodePacked(msg.sender, nonce));

            target = address( // derive the target deployment address.
                uint160( // downcast to match the address type.
                    uint256( // cast to uint to truncate upper digits.
                        keccak256( // compute CREATE2 hash using 4 inputs.
                            abi.encodePacked( // pack all inputs to the hash together.
                                bytes1(0xff), // pass in the control character.
                                address(this), // pass in the address of this contract.
                                salt, // pass in the salt from above.
                                initCodeHash // pass in hash of contract creation code.
                            )
                        )
                    )
                )
            );

            // determine if a contract is already deployed to the target address.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                exist := gt(extcodesize(target), 0)
            }

            // exit the loop if no contract is deployed to the target address.
            if (!exist) {
                break;
            }

            // otherwise, increment the nonce and derive a new salt.
            nonce++;
        }
    }

    function getTargetFromSeed(bytes memory initCode, string memory seed) internal view returns (address target) {
        // get the keccak256 hash of the init code for address derivation.
        bytes32 initCodeHash = keccak256(initCode);

        bytes32 salt = keccak256(abi.encodePacked(msg.sender, seed));

        target = address( // derive the target deployment address.
            uint160( // downcast to match the address type.
                uint256( // cast to uint to truncate upper digits.
                    keccak256( // compute CREATE2 hash using 4 inputs.
                        abi.encodePacked( // pack all inputs to the hash together.
                            bytes1(0xff), // pass in the control character.
                            address(this), // pass in the address of this contract.
                            salt, // pass in the salt from above.
                            initCodeHash // pass in hash of contract creation code.
                        )
                    )
                )
            )
        );
    }

    function creation(address addr, bytes memory initializationCalldata)
        private
        pure
        returns (bytes memory createCode)
    {
        createCode = initializationCalldata.length > 0
            ? abi.encodePacked(
                type(MinimalMakerWithCall).creationCode,
                abi.encode(address(addr), initializationCalldata)
            )
            : abi.encodePacked(type(MinimalMaker).creationCode, abi.encode(address(addr)));
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
import "@beandao/contracts/interfaces/IERC165.sol";
import "@beandao/contracts/library/Address.sol";
import "@beandao/contracts/library/BeaconDeployer.sol";
import {Ownership, IERC173} from "@beandao/contracts/library/Ownership.sol";
import {BeaconProxyDeployer} from "@beandao/contracts/library/BeaconProxyDeployer.sol";
import {MinimalProxyDeployer} from "@beandao/contracts/library/MinimalProxyDeployer.sol";
import {Multicall, IMulticall} from "@beandao/contracts/library/Multicall.sol";
import "./IFactory.sol";

/**
 * @title Factory V1
 * @author yoonsung.eth
 * @notice Abstract reusable contract into template and deploy them in small sizes `minimal proxy` and `beacon proxy`.
 * This contract can receive a fee lower than the deploy cost, and registered addresses do not have to pay the fee.
 * Beacon is managed in this contract, it can be useful if you need a scalable upgrade through the `beacon proxy`.
 * @dev The template to be registered may or may not have an `initialize` function.
 * However, at least a ERC173 and multicall for directed at self must be implemented.
 */
contract FactoryV1 is Ownership, Multicall, IFactory {
    using Address for address;

    /**
     * @notice template key for template info.
     */
    mapping(bytes32 => TemplateInfo) public templates;

    /**
     * @notice registered template for nonce.
     */
    mapping(address => uint256) private nonceForTemplate;

    /**
     * @notice template count.
     */
    uint256 public nonce = 1;

    /**
     * @notice base fee
     */
    uint256 public baseFee;

    /**
     * @notice fee collector
     */
    address payable public feeTo;

    /**
     * @notice requiring on deploy, allowlist contract.
     * @param feeAmount basic fee for ether amount
     * @param feeToAddr fee collector address
     */
    constructor(uint256 feeAmount, address payable feeToAddr) {
        baseFee = feeAmount;
        feeTo = feeToAddr;
        nonceForTemplate[address(0)] = type(uint256).max;
    }

    /**
     * @notice template id를 통해서 minimal proxy와 minimal beacon proxy를 배포하는 함수.
     * @dev 일반적으로 배포되는 컨트랙트와 같이 컨트랙트가 생성될 때 초기화 함수를 실행해야 한다면, initializationCallData에 호출할 함수를
     * serialize하여 주입하여야 합니다. 컨트랙트 소유권을 별도로 관리해야하는 경우 multicall을 통해서 명시적인 소유권 이전이 되어야 합니다.
     * @param templateId 배포할 컨트랙트의 template id
     * @param isBeacon 비콘으로 배포해야 할 것인지 결정하는 인자.
     * @param initializationCallData 컨트랙트가 생성될 때 호출할 직렬화된 초기화 함수 정보
     * @param calls 컨트랙트가 배포된 이후, 필요한 일련의 함수 호출 정보
     */
    function deploy(
        bool isBeacon,
        bytes32 templateId,
        bytes memory initializationCallData,
        bytes[] memory calls
    ) external payable returns (address deployed) {
        // 템플릿을 배포하기 위한 수수료가 적정 수준인지 확인.
        require(baseFee <= msg.value || owner == msg.sender, "Factory/Incorrect-amounts");
        // 수수료 전송
        feeTransfer(feeTo, msg.value);
        // 배포할 템플릿의 정보
        TemplateInfo memory tmp = templates[templateId];

        deployed = isBeacon
            ? BeaconProxyDeployer.deploy(tmp.btemplate, initializationCallData)
            : MinimalProxyDeployer.deploy(tmp.template, initializationCallData);

        // 부수적으로 호출할 데이터가 있다면, 배포된 컨트랙트에 추가적인 call을 할 수 있음.
        if (calls.length > 0) IMulticall(deployed).multicall(calls);
        // 이벤트 호출
        emit Deployed(deployed, msg.sender);
    }

    /**
     * @notice template id와 외부에서 관리되는 seed를 통해서 minimal proxy와 minimal beacon proxy를 배포하는 함수.
     * @dev 일반적으로 배포되는 컨트랙트와 같이 컨트랙트가 생성될 때 초기화 함수를 실행해야 한다면, initializationCallData에 호출할 함수를
     * serialize하여 주입하여야 합니다. 컨트랙트 소유권을 별도로 관리해야하는 경우 multicall을 통해서 명시적인 소유권 이전이 되어야 합니다.
     * @param seed 컨트랙트 주소 확정에 필요한 외부 seed
     * @param isBeacon 비콘으로 배포해야 할 것인지 결정하는 인자.
     * @param templateId 배포할 컨트랙트의 template id
     * @param initializationCallData 컨트랙트가 생성될 때 호출할 직렬화된 초기화 함수 정보
     * @param calls 컨트랙트가 배포된 이후, 필요한 일련의 함수 호출 정보
     */
    function deployWithSeed(
        string memory seed,
        bool isBeacon,
        bytes32 templateId,
        bytes memory initializationCallData,
        bytes[] memory calls
    ) external payable returns (address deployed) {
        // 템플릿을 배포하기 위한 수수료가 적정 수준인지 확인.
        require(baseFee <= msg.value || owner == msg.sender, "Factory/Incorrect-amounts");
        // 수수료 전송
        feeTransfer(feeTo, msg.value);
        // 배포할 템플릿의 정보
        TemplateInfo memory tmp = templates[templateId];

        deployed = isBeacon
            ? BeaconProxyDeployer.deploy(seed, tmp.btemplate, initializationCallData)
            : MinimalProxyDeployer.deploy(seed, tmp.template, initializationCallData);

        // 부수적으로 호출할 데이터가 있다면, 배포된 컨트랙트에 추가적인 call을 할 수 있음.
        if (calls.length > 0) IMulticall(deployed).multicall(calls);
        // 이벤트 호출
        emit Deployed(deployed, msg.sender);
    }

    /**
     * @notice template id와 초기화 데이터 통해서 minimal proxy와 minimal beacon proxy로 배포할 주소를 미리 파악하는 함수
     * @dev 연결된 지갑 주소에 따라 생성될 지갑 주소가 변경되므로, 연결되어 있는 주소를 필수로 확인하여야 합니다.
     * @param isBeacon 비콘으로 배포해야 할 것인지 결정하는 인자.
     * @param templateId 배포할 컨트랙트의 template id
     * @param initializationCallData 컨트랙트가 생성될 때 호출할 직렬화된 초기화 함수 정보
     */
    function compute(
        bool isBeacon,
        bytes32 templateId,
        bytes memory initializationCallData
    ) external view returns (address deployable) {
        TemplateInfo memory tmp = templates[templateId];
        deployable = isBeacon
            ? BeaconProxyDeployer.calculateAddress(tmp.btemplate, initializationCallData)
            : MinimalProxyDeployer.calculateAddress(tmp.template, initializationCallData);
    }

    /**
     * @notice template id와 Seed 문자열, 초기화 데이터 통해서 minimal proxy와 minimal beacon proxy로 배포할 주소를 미리 파악하는 함수
     * @dev 연결된 지갑 주소에 따라 생성될 지갑 주소가 변경되므로, 연결되어 있는 주소를 필수로 확인하여야 합니다.
     * @param seed 컨트랙트에 사용할 seed 문자열
     * @param isBeacon 비콘으로 배포해야 할 것인지 결정하는 인자.
     * @param templateId 배포할 컨트랙트의 template id
     * @param initializationCallData 컨트랙트가 생성될 때 호출할 직렬화된 초기화 함수 정보
     */
    function computeWithSeed(
        string memory seed,
        bool isBeacon,
        bytes32 templateId,
        bytes memory initializationCallData
    ) external view returns (address deployable) {
        TemplateInfo memory tmp = templates[templateId];
        deployable = isBeacon
            ? BeaconProxyDeployer.calculateAddress(seed, tmp.btemplate, initializationCallData)
            : MinimalProxyDeployer.calculateAddress(seed, tmp.template, initializationCallData);
    }

    /**
     * @notice Factori.eth에 등록되지 않은 컨트랙트를 Template로 하여 Minimal Proxy로 배포합니다.
     * @param templateAddr 템플릿으로 사용할 이미 배포된 컨트랙트 주소
     * @param initializationCallData 배포되면서 호출되어야 하는 초기화 함수
     * @param calls 초기화 함수 이외에, 호출되어야 하는 함수들의 배열
     */
    function clone(
        address templateAddr,
        bytes memory initializationCallData,
        bytes[] memory calls
    ) external payable returns (address deployed) {
        require(nonceForTemplate[templateAddr] == 0, "Factory/Registered-Template");
        // 템플릿을 배포하기 위한 수수료가 적정 수준인지 확인.
        require(baseFee == msg.value || owner == msg.sender, "Factory/Incorrect-amounts");
        // 수수료 전송
        feeTransfer(feeTo, msg.value);
        deployed = MinimalProxyDeployer.deploy(templateAddr, initializationCallData);
        if (calls.length > 0) IMulticall(deployed).multicall(calls);
    }

    /**
     * @notice Factori.eth에 등록되지 않은 컨트랙트를 Template로 하여 minimal proxy로 배포할 주소를 미리 파악하는 함수
     * @dev 연결된 지갑 주소에 따라 생성될 지갑 주소가 변경되므로, 연결되어 있는 주소를 필수로 확인하여야 합니다.
     * @param templateAddr 배포할 컨트랙트의 template id
     * @param initializationCallData 컨트랙트가 생성될 때 호출할 직렬화된 초기화 함수 정보
     */
    function computeClone(address templateAddr, bytes memory initializationCallData)
        external
        view
        returns (address deployable)
    {
        deployable = MinimalProxyDeployer.calculateAddress(templateAddr, initializationCallData);
    }

    /**
     * @notice template id에 따라서 컨트랙트를 배포하기 위한 필요 가격을 가져오는 함
     * @dev 연결된 지갑 주소에 따라 생성될 지갑 주소가 변경되므로, 연결되어 있는 주소를 필수로 확인하여야 합니다.
     * @return price 이더리움으로 구성된 값을 가짐.
     */
    function getPrice() external view returns (uint256 price) {
        price = baseFee;
    }

    /**
     * @notice 템플릿으로 사용되기 적합한 인터페이스가 구현된 컨트랙트를 템플릿으로 가격과 함께 등록함.
     * @dev 같은 템플릿이 비콘과, 일반적인 템플릿으로 등록될 수 있습니다. 따라서 선택적으로 사용 가능합니다.
     * @param templateAddr 템플릿으로 사용될 컨트랙트의 주소
     */
    function addTemplate(address templateAddr) external onlyOwner {
        require(nonceForTemplate[templateAddr] == 0, "Factory/Non-Valid");
        bytes32 key = keccak256(abi.encode(templateAddr, nonce));
        address beaconAddr = BeaconDeployer.deploy(templateAddr);
        templates[key] = TemplateInfo({template: templateAddr, btemplate: beaconAddr});
        nonceForTemplate[templateAddr] = nonce++;
        emit NewTemplate(key, templateAddr, beaconAddr);
    }

    /**
     * @notice 등록된 템플릿의 정보를 변경하는 함수, 비콘인 경우에는 템플릿을 업데이트 할 수 있으나 비콘이 아니라면 업데이트 불가능.
     * @param key 업데이트 될 템플릿의 아이디
     * @param templateAddr 비콘일 경우 템플릿 주소, 템플릿 소유주 주소를 순서대로 인코딩
     */
    function updateTemplate(bytes32 key, address templateAddr) external onlyOwner {
        require(templateAddr != address(0), "Factory/Non-Valid");
        require(nonceForTemplate[templateAddr] == 0, "Factory/registered-before");
        require(templateAddr.isContract(), "Factory/is-not-Contract");
        TemplateInfo memory tmp = templates[key];
        tmp.template = templateAddr;
        (bool success, ) = tmp.btemplate.call(abi.encode(templateAddr));
        assert(success);
        templates[key] = tmp;
        emit UpdatedTemplate(key, tmp.template);
    }

    /**
     * @notice 등록된 템플릿을 삭제하는 함수
     * @param key 삭제될 템플릿의 아이디
     */
    function removeTemplate(bytes32 key) external onlyOwner {
        TemplateInfo memory tmp = templates[key];
        require(tmp.template != address(0), "Factory/Non-Exist");
        delete templates[key];
        emit DeletedTemplate(key);
    }

    /**
     * @notice 고정 수수료를 변경
     * @param newFee 변경된 수수료
     */
    function changeFee(uint256 newFee) external onlyOwner {
        uint256 prevFee = baseFee;
        baseFee = newFee;
        emit FeeChanged(prevFee, newFee);
    }

    /**
     * @notice 수수료를 수취할 대상 변경
     * @param newFeeTo 수취할 대상 주소
     */
    function changeFeeTo(address payable newFeeTo) external onlyOwner {
        address prevFeeTo = feeTo;
        feeTo = newFeeTo;
        emit FeeToChanged(prevFeeTo, newFeeTo);
    }

    /**
     * @notice Factori.eth에 쌓여있는 ETH와 토큰을 호출하여, 수수료 수취 주소에 전송함
     * @param tokenAddr 수취할 토큰 주소
     */
    function collect(address tokenAddr) external onlyOwner {
        IERC20(tokenAddr).transfer(feeTo, IERC20(tokenAddr).balanceOf(address(this)));
    }

    function recoverOwnership(address deployed, address to) external onlyOwner {
        IERC173(deployed).transferOwnership(to);
    }

    function feeTransfer(address to, uint256 amount) internal returns (bool callStatus) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
            let returnDataSize := returndatasize()
            if iszero(callStatus) {
                returndatacopy(0, 0, returnDataSize)
                revert(0, returnDataSize)
            }
        }
    }
}

/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

interface IFactory {
    struct TemplateInfo {
        address template;
        address btemplate;
    }

    event Deployed(address deployed, address owner);
    event NewTemplate(bytes32 indexed key, address template, address beacon);
    event UpdatedTemplate(bytes32 indexed key, address template);
    event DeletedTemplate(bytes32 indexed key);
    event FeeChanged(uint256 prevFee, uint256 fee);
    event FeeToChanged(address prevFeeTo, address feeTo);

    function deploy(
        bool isBeacon,
        bytes32 templateId,
        bytes memory initializationCallData,
        bytes[] memory calls
    ) external payable returns (address deployed);

    function deployWithSeed(
        string memory seed,
        bool isBeacon,
        bytes32 templateId,
        bytes memory initializationCallData,
        bytes[] memory calls
    ) external payable returns (address deployed);

    function compute(
        bool isBeacon,
        bytes32 templateId,
        bytes memory initializationCallData
    ) external view returns (address deployable);

    function computeWithSeed(
        string memory seed,
        bool isBeacon,
        bytes32 templateId,
        bytes memory initializationCallData
    ) external view returns (address deployable);

    function clone(
        address templateAddr,
        bytes memory initializationCallData,
        bytes[] memory calls
    ) external payable returns (address deployed);

    function computeClone(address templateAddr, bytes memory initializationCallData)
        external
        view
        returns (address deployable);

    function getPrice() external view returns (uint256 price);

    function addTemplate(address templateAddr) external;

    function updateTemplate(bytes32 key, address templateAddr) external;

    function removeTemplate(bytes32 key) external;

    function changeFee(uint256 newFee) external;

    function changeFeeTo(address payable newFeeTo) external;

    function collect(address tokenAddr) external;
}