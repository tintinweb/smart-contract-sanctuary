// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IRelayEncoder.sol";
import "Encoding.sol";

contract RelayEncoder is IRelayEncoder {
    using Encoding for uint256;

    // first chain specific byte
    bytes public chain;

    /**
     * @dev Sets the chain first byte
     */
    constructor(bytes memory _chain) {
        // NOTE: for kusama first byte is 06, for polkadot first byte is 07
        chain = _chain;
    }

    // dev Encode 'bond' relay call
    // @param controller_address: Address of the controller
    // @param amount: The amount to bond
    // @param reward_destination: the account that should receive the reward
    // @returns The bytes associated with the encoded call
    function encode_bond(
        uint256 controller_address, 
        uint256 amount, 
        bytes memory reward_destination
    ) external override view returns (bytes memory result) {
        return bytes.concat(chain, hex"0000", bytes32(controller_address), amount.scaleCompactUint(), reward_destination);
    }

    // dev Encode 'bond_extra' relay call
    // @param amount: The extra amount to bond
    // @returns The bytes associated with the encoded call
    function encode_bond_extra(uint256 amount) external override view returns (bytes memory) {
        return bytes.concat(chain, hex"01", amount.scaleCompactUint());
    }

    // dev Encode 'unbond' relay call
    // @param amount: The amount to unbond
    // @returns The bytes associated with the encoded call
    function encode_unbond(uint256 amount) external override view returns (bytes memory) {
        return bytes.concat(chain, hex"02", amount.scaleCompactUint());
    }

    // dev Encode 'rebond' relay call
    // @param amount: The amount to rebond
    // @returns The bytes associated with the encoded call
    function encode_rebond(uint256 amount) external override view returns (bytes memory) {
        return bytes.concat(chain, hex"13", amount.scaleCompactUint());
    }

    // dev Encode 'withdraw_unbonded' relay call
    // @param slashes: Weight hint, number of slashing spans
    // @returns The bytes associated with the encoded call
    function encode_withdraw_unbonded(uint32 slashes) external override view returns (bytes memory) {
        if (slashes < 1<<8) {
            return bytes.concat(chain, hex"03", bytes1(uint8(slashes)), bytes3(0));
        }
        if(slashes < 1 << 16) {
            uint32 bt2 = slashes / 256;
            uint32 bt1 = slashes - bt2 * 256;
            return bytes.concat(chain, hex"03", bytes1(uint8(bt1)), bytes1(uint8(bt2)), bytes2(0));
        }
        if(slashes < 1 << 24) {
            uint32 bt3 = slashes / 65536;
            uint32 bt2 = (slashes - bt3 * 65536) / 256;
            uint32 bt1 = slashes - bt3 * 65536 - bt2 * 256;
            return bytes.concat(chain, hex"03", bytes1(uint8(bt1)), bytes1(uint8(bt2)), bytes1(uint8(bt3)), bytes1(0));
        }
        uint32 bt4 = slashes / 16777216;
        uint32 bt3 = (slashes - bt4 * 16777216) / 65536;
        uint32 bt2 = (slashes - bt4 * 16777216 - bt3 * 65536) / 256;
        uint32 bt1 = slashes - bt4 * 16777216 - bt3 * 65536 - bt2 * 256;
        return bytes.concat(chain, hex"03", bytes1(uint8(bt1)), bytes1(uint8(bt2)), bytes1(uint8(bt3)), bytes1(uint8(bt4)));
    }

    // dev Encode 'nominate' relay call
    // @param nominees: An array of AccountIds corresponding to the accounts we will nominate
    // @param blocked: Whether or not the validator is accepting more nominations
    // @returns The bytes associated with the encoded call
    function encode_nominate(uint256 [] memory nominees) external override view returns (bytes memory) {
        if (nominees.length == 0) {
            return bytes.concat(chain, hex"0500");
        }
        bytes memory result = bytes.concat(chain, hex"05", nominees.length.scaleCompactUint());
        for (uint256 i = 0; i < nominees.length; ++i) {
            result = bytes.concat(result, hex"00", bytes32(nominees[i]));
        }
        return result;
    }

    // dev Encode 'chill' relay call
    // @returns The bytes associated with the encoded call
    function encode_chill() external override view returns (bytes memory) {
        return bytes.concat(chain, hex"06");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @author The Moonbeam Team
/// @title The interface through which solidity contracts will interact with Relay Encoder
/// We follow this same interface including four-byte function selectors, in the precompile that
/// wraps the pallet
interface IRelayEncoder {
    // dev Encode 'bond' relay call
    // Selector: 31627376
    // @param controller_address: Address of the controller
    // @param amount: The amount to bond
    // @param reward_destination: the account that should receive the reward
    // @returns The bytes associated with the encoded call
    function encode_bond(uint256 controller_address, uint256 amount, bytes memory reward_destination) external view returns (bytes memory result);

    // dev Encode 'bond_extra' relay call
    // Selector: 49def326
    // @param amount: The extra amount to bond
    // @returns The bytes associated with the encoded call
    function encode_bond_extra(uint256 amount) external view returns (bytes memory result);

    // dev Encode 'unbond' relay call
    // Selector: bc4b2187
    // @param amount: The amount to unbond
    // @returns The bytes associated with the encoded call
    function encode_unbond(uint256 amount) external view returns (bytes memory result);

    // dev Encode 'withdraw_unbonded' relay call
    // Selector: 2d220331
    // @param slashes: Weight hint, number of slashing spans
    // @returns The bytes associated with the encoded call
    function encode_withdraw_unbonded(uint32 slashes) external view returns (bytes memory result);

    // dev Encode 'validate' relay call
    // Selector: 3a0d803a
    // @param comission: Comission of the validator as parts_per_billion
    // @param blocked: Whether or not the validator is accepting more nominations
    // @returns The bytes associated with the encoded call
    // selector: 3a0d803a
    // function encode_validate(uint256 comission, bool blocked) external pure returns (bytes memory result);

    // dev Encode 'nominate' relay call
    // Selector: a7cb124b
    // @param nominees: An array of AccountIds corresponding to the accounts we will nominate
    // @param blocked: Whether or not the validator is accepting more nominations
    // @returns The bytes associated with the encoded call
    function encode_nominate(uint256 [] memory nominees) external view returns (bytes memory result);

    // dev Encode 'chill' relay call
    // Selector: bc4b2187
    // @returns The bytes associated with the encoded call
    function encode_chill() external view returns (bytes memory result);

    // dev Encode 'set_payee' relay call
    // Selector: 9801b147
    // @param reward_destination: the account that should receive the reward
    // @returns The bytes associated with the encoded call
    // function encode_set_payee(bytes memory reward_destination) external pure returns (bytes memory result);

    // dev Encode 'set_controller' relay call
    // Selector: 7a8f48c2
    // @param controller: The controller address
    // @returns The bytes associated with the encoded call
    // function encode_set_controller(uint256 controller) external pure returns (bytes memory result);

    // dev Encode 'rebond' relay call
    // Selector: add6b3bf
    // @param amount: The amount to rebond
    // @returns The bytes associated with the encoded call
    function encode_rebond(uint256 amount) external view returns (bytes memory result);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Encoding {
    /**
    * @notice Converting uint256 value to le bytes
    * @param value - uint256 value
    * @param len - length of output bytes array
    */
    function toLeBytes(uint256 value, uint256 len) internal pure returns(bytes memory) {
        bytes memory out = new bytes(len);
        for (uint256 idx = 0; idx < len; ++idx) {
            out[idx] = bytes1(uint8(value));
            value = value >> 8;
        }
        return out;
    }

    /**
    * @notice Converting uint256 value to bytes
    * @param value - uint256 value
    */
    function scaleCompactUint(uint256 value) internal pure returns(bytes memory) {
        if (value < 1<<6) {
            return toLeBytes(value << 2, 1);
        }
        else if(value < 1 << 14) {
            return toLeBytes((value << 2) + 1, 2);
        }
        else if(value < 1 << 30) {
            return toLeBytes((value << 2) + 2, 4);
        }
        else {
            uint256 numBytes = 0;
            {
                uint256 m = value;
                for (; numBytes < 256 && m != 0; ++numBytes) {
                    m = m >> 8;
                }
            }

            bytes memory out = new bytes(numBytes + 1);
            out[0] = bytes1(uint8(((numBytes - 4) << 2) + 3));
            for (uint256 i = 0; i < numBytes; ++i) {
                out[i + 1] = bytes1(uint8(value & 0xFF));
                value = value >> 8;
            }
            return out;
        }
    }
}