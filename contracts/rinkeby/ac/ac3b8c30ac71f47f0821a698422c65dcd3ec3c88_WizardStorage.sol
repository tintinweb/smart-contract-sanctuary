/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;

contract WizardStorage {
    mapping(uint256 => bytes) private wizardTraits;

    mapping(uint16 => uint16[]) private traitsToAffinities;

    // This should not be callabe only once per wizard
    function storeWizardTraits(
        uint256[] calldata ids,
        uint16[6][] calldata traits
    ) public {
        for (uint256 id = 0; id < ids.length; id++) {
            wizardTraits[ids[id]] = encode(
                traits[id][0],
                traits[id][1],
                traits[id][2],
                traits[id][3],
                traits[id][4],
                traits[id][5]
            );
        }
    }

    // This should not be callabe only once per wizard
    function storeTraitAffinities(
        uint16[] calldata traits,
        uint16[][] calldata affinities
    ) public {
        for (uint256 i = 0; i < traits.length; i++) {
            traitsToAffinities[traits[i]] = affinities[i];
        }
    }

    function getWizardTraits(uint256 id)
        public
        view
        returns (
            uint16 t0,
            uint16 t1,
            uint16 t2,
            uint16 t3,
            uint16 t4,
            uint16 t5
        )
    {
        return decode(wizardTraits[id]);
    }

    function getTraitAffinities(uint16 id)
        public
        view
        returns (uint16[] memory)
    {
        return traitsToAffinities[id];
    }

    function getWizardAffinities(uint256 id)
        public
        view
        returns (uint16[] memory)
    {
        (, uint16 t1, uint16 t2, uint16 t3, uint16 t4, uint16 t5) = decode(
            wizardTraits[id]
        );

        uint16[] storage affinityT1 = traitsToAffinities[t1];
        uint16[] storage affinityT2 = traitsToAffinities[t2];
        uint16[] storage affinityT3 = traitsToAffinities[t3];
        uint16[] storage affinityT4 = traitsToAffinities[t4];
        uint16[] storage affinityT5 = traitsToAffinities[t5];

        uint16[] memory affinitiesList = new uint16[](
            affinityT1.length +
                affinityT2.length +
                affinityT3.length +
                affinityT4.length +
                affinityT5.length
        );

        uint256 lastIndexWritten = 0;

        if (t1 != 7777) {
            for (uint256 i = 0; i < affinityT1.length; i++) {
                affinitiesList[i] = affinityT1[i];
            }
        }

        if (t2 != 7777) {
            lastIndexWritten = lastIndexWritten + affinityT1.length;
            for (uint256 i = 0; i < affinityT2.length; i++) {
                affinitiesList[lastIndexWritten + i] = affinityT2[i];
            }
        }

        if (t3 != 7777) {
            lastIndexWritten = lastIndexWritten + affinityT2.length;
            for (uint8 i = 0; i < affinityT3.length; i++) {
                affinitiesList[lastIndexWritten + i] = affinityT3[i];
            }
        }

        if (t4 != 7777) {
            lastIndexWritten = lastIndexWritten + affinityT3.length;
            for (uint8 i = 0; i < affinityT4.length; i++) {
                affinitiesList[lastIndexWritten + i] = affinityT4[i];
            }
        }

        if (t5 != 7777) {
            lastIndexWritten = lastIndexWritten + affinityT4.length;
            for (uint8 i = 0; i < affinityT5.length; i++) {
                affinitiesList[lastIndexWritten + i] = affinityT5[i];
            }
        }

        return affinitiesList;
    }

    function getWizardTraitsEncoded(uint256 id)
        public
        view
        returns (bytes memory)
    {
        return wizardTraits[id];
    }

    function encode(
        uint16 t0,
        uint16 t1,
        uint16 t2,
        uint16 t3,
        uint16 t4,
        uint16 t5
    ) internal pure returns (bytes memory) {
        bytes memory data = new bytes(14);

        assembly {
            mstore(add(data, 32), 32)

            mstore(add(data, 34), shl(240, t0))
            mstore(add(data, 36), shl(240, t1))
            mstore(add(data, 38), shl(240, t2))
            mstore(add(data, 40), shl(240, t3))
            mstore(add(data, 42), shl(240, t4))
            mstore(add(data, 44), shl(240, t5))
        }

        return data;
    }

    function decode(bytes memory data)
        internal
        pure
        returns (
            uint16 t0,
            uint16 t1,
            uint16 t2,
            uint16 t3,
            uint16 t4,
            uint16 t5
        )
    {
        assembly {
            let len := mload(add(data, 0))

            t0 := mload(add(data, 4))

            t1 := mload(add(data, 6))

            t2 := mload(add(data, 8))

            t3 := mload(add(data, 10))

            t4 := mload(add(data, 12))
            t5 := mload(add(data, 14))
        }
    }
}