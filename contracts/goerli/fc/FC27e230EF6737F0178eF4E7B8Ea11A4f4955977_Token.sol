/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

interface IBurn {
    function burn(uint256 value) external returns (bool);

    function burnFrom(address from, uint256 value) external returns (bool);
}

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

interface IMint {
    function mint(uint256 value) external returns (bool);

    function mintTo(address to, uint256 value) external returns (bool);
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

import "../interfaces/IERC20.sol";

abstract contract ERC20 is IERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address spender, uint256 value) external virtual returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external virtual returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external virtual returns (bool) {
        allowance[from][msg.sender] -= value;
        _transfer(from, to, value);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual {
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    function _approve(
        address _owner,
        address spender,
        uint256 value
    ) internal virtual {
        require(spender != address(this), "ERC20/Impossible-Approve-to-Self");
        allowance[_owner][spender] = value;
        emit Approval(_owner, spender, value);
    }
}

/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "./EIP712.sol";
import "../interfaces/IERC2612.sol";
import {ERC20} from "./ERC20.sol";

/**
 * @title Permit
 * @notice An alternative to approveWithAuthorization, provided for
 * compatibility with the draft EIP2612 proposed by Uniswap.
 * @dev Differences:
 * - Uses sequential nonce, which restricts transaction submission to one at a
 *   time, or else it will revert
 * - Has deadline (= validBefore - 1) but does not have validAfter
 * - Doesn't have a way to change allowance atomically to prevent ERC20 multiple
 *   withdrawal attacks
 */
abstract contract ERC2612 is ERC20, IERC2612 {
    bytes32 public immutable PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    bytes32 public DOMAIN_SEPARATOR;

    string public version;

    mapping(address => uint256) public nonces;

    /**
     * @notice Initialize EIP712 Domain Separator
     * @param _name        name of contract
     * @param _version     version of contract
     */
    function _initDomainSeparator(string memory _name, string memory _version) internal {
        version = _version;
        DOMAIN_SEPARATOR = EIP712.hashDomainSeperator(_name, _version, address(this));
    }

    /**
     * @notice Verify a signed approval permit and execute if valid
     * @param owner     Token owner's address (Authorizer)
     * @param spender   Spender's address
     * @param value     Amount of allowance
     * @param deadline  The time at which this expires (unix time)
     * @param v         v of the signature
     * @param r         r of the signature
     * @param s         s of the signature
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual {
        require(owner != address(0), "ERC2612/Invalid-address-0");
        require(deadline >= block.timestamp, "ERC2612/Expired-time");

        bytes32 digest = EIP712.hashMessage(
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
        );

        address recovered = ecrecover(digest, v, r, s);
        require(recovered != address(0) && recovered == owner, "ERC2612/Invalid-Signature");

        _approve(owner, spender, value);
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

import "@beandao/contracts/interfaces/IMint.sol";
import "@beandao/contracts/interfaces/IBurn.sol";
import "@beandao/contracts/interfaces/IERC165.sol";
import {ERC20, IERC20} from "@beandao/contracts/library/ERC20.sol";
import {ERC2612, IERC2612} from "@beandao/contracts/library/ERC2612.sol";
import {Ownership, IERC173} from "@beandao/contracts/library/Ownership.sol";
import {Multicall, IMulticall} from "@beandao/contracts/library/Multicall.sol";

contract Token is ERC20, ERC2612, Ownership, Multicall, IBurn, IMint, IERC165 {
    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals,
        string memory tokenVersion
    ) {
        _initDomainSeparator(tokenName, tokenVersion);
        name = tokenName;
        symbol = tokenSymbol;
        decimals = tokenDecimals;
        balanceOf[address(this)] = type(uint256).max;
    }

    function mint(uint256 value) external onlyOwner returns (bool) {
        balanceOf[msg.sender] += value;
        totalSupply += value;
        emit Transfer(address(0), msg.sender, value);
        return true;
    }

    function mintTo(address to, uint256 value) external onlyOwner returns (bool) {
        balanceOf[to] += value;
        totalSupply += value;
        emit Transfer(address(0), to, value);
        return true;
    }

    function burn(uint256 value) external onlyOwner returns (bool) {
        balanceOf[msg.sender] -= value;
        totalSupply -= value;
        emit Transfer(msg.sender, address(0), value);
        return true;
    }

    function burnFrom(address from, uint256 value) external onlyOwner returns (bool) {
        allowance[from][msg.sender] -= value;
        balanceOf[from] -= value;
        totalSupply -= value;
        emit Transfer(from, address(0), value);
        return true;
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return
            // ERC20
            interfaceId == type(IERC20).interfaceId ||
            interfaceId == type(IMint).interfaceId ||
            interfaceId == type(IBurn).interfaceId ||
            // ERC2612
            interfaceId == type(IERC2612).interfaceId ||
            // ITemplateV1(ERC165, ERC173, IMulticall)
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC173).interfaceId ||
            interfaceId == type(IMulticall).interfaceId;
    }
}