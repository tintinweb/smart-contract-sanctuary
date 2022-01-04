/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

interface IERC1271 {
    // bytes4(keccak256("isValidSignature(bytes32,bytes)")
    // bytes4 constant internal MAGICVALUE = 0x1626ba7e;

    /**
     * @dev Should return whether the signature provided is valid for the provided hash
     * @param _hash      Hash of the data to be signed
     * @param _signature Signature byte array associated with _hash
     *
     * MUST return the bytes4 magic value 0x1626ba7e when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     */
    function isValidSignature(bytes32 _hash, bytes memory _signature) external view returns (bytes4 magicValue);
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

library EIP712 {
    bytes32 internal constant EIP712DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /**
     * @dev Calculates a EIP712 domain separator.
     * @param name The EIP712 domain name.
     * @param version The EIP712 domain version.
     * @param verifyingContract The EIP712 verifying contract.
     * @return result EIP712 domain separator.
     */
    function hashDomainSeperator(
        string memory name,
        string memory version,
        address verifyingContract
    ) internal view returns (bytes32 result) {
        bytes32 typehash = EIP712DOMAIN_TYPEHASH;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let nameHash := keccak256(add(name, 32), mload(name))
            let versionHash := keccak256(add(version, 32), mload(version))
            let chainId := chainid()

            let memPtr := mload(64)

            mstore(memPtr, typehash)
            mstore(add(memPtr, 32), nameHash)
            mstore(add(memPtr, 64), versionHash)
            mstore(add(memPtr, 96), chainId)
            mstore(add(memPtr, 128), verifyingContract)

            result := keccak256(memPtr, 160)
        }
    }

    /**
     * @dev Calculates EIP712 encoding for a hash struct with a given domain hash.
     * @param domainHash Hash of the domain domain separator data, computed with getDomainHash().
     * @param hashStruct The EIP712 hash struct.
     * @return result EIP712 hash applied to the given EIP712 Domain.
     */
    function hashMessage(bytes32 domainHash, bytes32 hashStruct) internal pure returns (bytes32 result) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let memPtr := mload(64)

            mstore(memPtr, 0x1901000000000000000000000000000000000000000000000000000000000000) // EIP191 header
            mstore(add(memPtr, 2), domainHash) // EIP712 domain hash
            mstore(add(memPtr, 34), hashStruct) // Hash of struct

            result := keccak256(memPtr, 66)
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
import "@beandao/contracts/interfaces/IERC1271.sol";
import "@beandao/contracts/interfaces/IERC2612.sol";
import "@beandao/contracts/library/Address.sol";
import "@beandao/contracts/library/Initializer.sol";
import "@beandao/contracts/library/EIP712.sol";
import {Ownership, IERC173} from "@beandao/contracts/library/Ownership.sol";
import "./IEscrow.sol";
import "./IVesting.sol";

/**
 * @title Escrow
 * @author yoonsung.eth
 * @notice Erica token을 예탁 할 수 있는 컨트랙트이며, 여기네는 대상 토큰만 예치할 수 있습니다.
 * 추가적인 보상을 등록해야 한다면 해당 정보를 베스팅 단계에서 등록할 수 있습니다.
 * @dev 단 하나의 Ownership을 가집니다. 베스팅 컨트랙트와
 */
contract Escrow is Ownership, Initializer, IEscrow {
    using Address for address;

    string public constant name = "Erica Escrow";
    string public constant version = "1";
    bytes32 public constant VESTING_TYPEHASH =
        keccak256(
            "Vesting(address recruiter,address to,uint256 amount,address subToken,uint256 subAmount,uint32 startTime,uint32 endTime,uint256 nonce)"
        );

    IERC20 public social;
    address public vestingContract;
    bytes32 public DOMAIN_SEPARATOR;
    mapping(address => uint256) public nonces;

    mapping(address => uint256) public deposits;

    event Deposited(address indexed customer, uint256 amount);
    event Withdrew(address indexed customer, uint256 amount);
    event Locked(address indexed recipient, address indexed vestingContract);

    /**
     * @notice 해당 컨트랙트를 초기화 합니다.
     * @param socialToken 해당 컨트랙트에 예치되어야 하는 토큰 주소
     * @param vestingAddr 토큰을 실제로 수여할 컨트랙트 주소
     */
    function initialize(address socialToken, address vestingAddr) external initializer {
        social = IERC20(socialToken);
        vestingContract = vestingAddr;
        _transferOwnership(msg.sender);
        DOMAIN_SEPARATOR = EIP712.hashDomainSeperator(name, version, address(this));
    }

    /**
     * @notice Social 토큰을 예치하는 함수입니다. 이를 호출하기 위해서는 토큰이 해당 컨트랙트에 approve되어 있어야 합니다.
     * @param amount 예치할 토큰의 수량
     */
    function deposit(uint256 amount) external {
        require(social.transferFrom(msg.sender, address(this), amount));
        unchecked {
            deposits[msg.sender] += amount;
        }
        emit Deposited(msg.sender, amount);
    }

    /**
     * @notice Social 토큰을 예치하는 함수입니다. 이를 호출하기 위해서는 ERC2612를 만족하는 서명값과 제한 시간을 필요로 합니다.
     * @param amount 예치할 토큰의 수량
     * @param deadline 해당 서명의 제한 시간
     * @param v 서명 값 v
     * @param r 서명 값 r
     * @param s 서명 값 s
     */
    function depositWithSig(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        IERC2612(address(social)).permit(msg.sender, address(this), amount, deadline, v, r, s);
        require(social.transferFrom(msg.sender, address(this), amount));
        unchecked {
            deposits[msg.sender] += amount;
        }
        emit Deposited(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        deposits[msg.sender] -= amount;
        social.transfer(msg.sender, amount);
        emit Withdrew(msg.sender, amount);
    }

    /**
     * @notice 예치되어 있는 토큰을 특정 주소로 할당하는 함수이며, 이를 통해서 Vesting Contract를 호출하게 됩니다.
     * recruiter는 아래 정보와 함께 서명값을 해당 컨트랙트의 소유자에게 전송하여야 합니다.
     * @param recruiter 토큰을 예치한 당사자이자, 토큰을 지불할 주소
     * @param to 토큰을 수여할 당사자이자, 토큰을 수여받을 주소
     * @param amount 토큰을 수여할 수량
     * @param subToken 추가적인 보상으로 지급할 토큰 주소
     * @param subAmount 추가적인 보상으로 지급할 토큰 수량
     * @param startTime 토큰을 수여할 시작 시간
     * @param endTime 토큰 수여가 종료될 시간
     * @param v 서명 값 v
     * @param r 서명 값 r
     * @param s 서명 값 s
     */
    function vesting(
        address recruiter,
        address to,
        uint256 amount,
        address subToken,
        uint256 subAmount,
        uint32 startTime,
        uint32 endTime,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external onlyOwner {
        uint256 nonce = nonces[recruiter]++;
        bytes32 digest = EIP712.hashMessage(
            DOMAIN_SEPARATOR,
            keccak256(
                abi.encode(VESTING_TYPEHASH, recruiter, to, amount, subToken, subAmount, startTime, endTime, nonce)
            )
        );

        if (recruiter.isContract()) {
            require(verify(recruiter, digest, v, r, s), "failed verify");
        } else {
            require(recruiter == ecrecover(digest, v, r, s), "failed verify");
        }
        // 베스팅 컨트랙트로 토큰 전송
        social.transfer(vestingContract, amount);
        // 전송한 만큼 리크루터의 토큰 수량 삭감
        deposits[recruiter] -= amount;
        // 추가로 부여할 토큰이 있다면 베스팅으로 전송
        if (subToken != address(0) && subAmount > 0) {
            IERC20(subToken).transferFrom(recruiter, vestingContract, subAmount);
        }
        // 베스팅 호출
        assert(IVesting(vestingContract).lock(recruiter, to, amount, subToken, subAmount, startTime, endTime));
        // 이벤트 호출
        emit Locked(to, vestingContract);
    }

    function verify(
        address recruiter,
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (bool success) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let reuse := mload(0x40)
            // Write the abi-encoded calldata to memory piece by piece:
            // EIP 1271 sig
            mstore(reuse, 0x1626ba7e00000000000000000000000000000000000000000000000000000000)
            mstore(add(reuse, 4), digest) // "digest" argument. No mask as it's a full 32 byte value.
            mstore(add(reuse, 36), 0x0000000000000000000000000000000000000000000000000000000000000040)
            mstore(add(reuse, 68), 0x0000000000000000000000000000000000000000000000000000000000000041)
            mstore(add(reuse, 133), and(v, 0xff)) // Finally append the "v" argument. with mask uint8
            mstore(add(reuse, 100), r) // "r" argument. No mask as it's a full 32 byte value.
            mstore(add(reuse, 132), s) // "s" argument. No mask as it's a full 32 byte value.
            // use 101 because the calldata length is 4 + 32 * 5 + 1.
            let callStatus := staticcall(gas(), recruiter, reuse, 165, 0, 32)
            let returnDataSize := returndatasize()
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }
            // returndata copy
            returndatacopy(reuse, 0, returnDataSize)
            switch mload(reuse)
            case 0x1626ba7e00000000000000000000000000000000000000000000000000000000 {
                success := 1
            }
            case 0xffffffff00000000000000000000000000000000000000000000000000000000 {
                success := 0
            }
            default {
                success := 0
            }
        }
    }
}

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
pragma solidity ^0.8.0;

interface IEscrow {
    /**
     * @notice Social 토큰을 예치하는 함수입니다. 이를 호출하기 위해서는 토큰이 해당 컨트랙트에 approve되어 있어야 합니다.
     * @param amount 예치할 토큰의 수량
     */
    function deposit(uint256 amount) external;

    /**
     * @notice Social 토큰을 예치하는 함수입니다. 이를 호출하기 위해서는 ERC2612를 만족하는 서명값과 제한 시간을 필요로 합니다.
     * @param amount 예치할 토큰의 수량
     * @param deadline 해당 서명의 제한 시간
     * @param v 서명 값 v
     * @param r 서명 값 r
     * @param s 서명 값 s
     */
    function depositWithSig(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function withdraw(uint256 amount) external;

    /**
     * @notice 예치되어 있는 토큰을 특정 주소로 할당하는 함수이며, 이를 통해서 Vesting Contract를 호출하게 됩니다.
     * recruiter는 아래 정보와 함께 서명값을 해당 컨트랙트의 소유자에게 전송하여야 합니다.
     * @param recruiter 토큰을 예치한 당사자이자, 토큰을 지불할 주소
     * @param to 토큰을 수여할 당사자이자, 토큰을 수여받을 주소
     * @param amount 토큰을 수여할 수량
     * @param subToken 추가적인 보상으로 지급할 토큰 주소
     * @param subAmount 추가적인 보상으로 지급할 토큰 수량
     * @param startTime 토큰을 수여할 시작 시간
     * @param endTime 토큰 수여가 종료될 시간
     * @param v 서명 값 v
     * @param r 서명 값 r
     * @param s 서명 값 s
     */
    function vesting(
        address recruiter,
        address to,
        uint256 amount,
        address subToken,
        uint256 subAmount,
        uint32 startTime,
        uint32 endTime,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
pragma solidity ^0.8.0;

interface IVesting {
    function lock(
        address recruiter,
        address to,
        uint256 amount,
        address subToken,
        uint256 subAmount,
        uint32 startTime,
        uint32 endTime
    ) external returns (bool);
}