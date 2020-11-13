// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.7.0;


/**
* @notice Deserialization library for Umbral objects
*/
library UmbralDeserializer {

    struct Point {
        uint8 sign;
        uint256 xCoord;
    }

    struct Capsule {
        Point pointE;
        Point pointV;
        uint256 bnSig;
    }

    struct CorrectnessProof {
        Point pointE2;
        Point pointV2;
        Point pointKFragCommitment;
        Point pointKFragPok;
        uint256 bnSig;
        bytes kFragSignature; // 64 bytes
        bytes metadata; // any length
    }

    struct CapsuleFrag {
        Point pointE1;
        Point pointV1;
        bytes32 kFragId;
        Point pointPrecursor;
        CorrectnessProof proof;
    }

    struct PreComputedData {
        uint256 pointEyCoord;
        uint256 pointEZxCoord;
        uint256 pointEZyCoord;
        uint256 pointE1yCoord;
        uint256 pointE1HxCoord;
        uint256 pointE1HyCoord;
        uint256 pointE2yCoord;
        uint256 pointVyCoord;
        uint256 pointVZxCoord;
        uint256 pointVZyCoord;
        uint256 pointV1yCoord;
        uint256 pointV1HxCoord;
        uint256 pointV1HyCoord;
        uint256 pointV2yCoord;
        uint256 pointUZxCoord;
        uint256 pointUZyCoord;
        uint256 pointU1yCoord;
        uint256 pointU1HxCoord;
        uint256 pointU1HyCoord;
        uint256 pointU2yCoord;
        bytes32 hashedKFragValidityMessage;
        address alicesKeyAsAddress;
        bytes5  lostBytes;
    }

    uint256 constant BIGNUM_SIZE = 32;
    uint256 constant POINT_SIZE = 33;
    uint256 constant SIGNATURE_SIZE = 64;
    uint256 constant CAPSULE_SIZE = 2 * POINT_SIZE + BIGNUM_SIZE;
    uint256 constant CORRECTNESS_PROOF_SIZE = 4 * POINT_SIZE + BIGNUM_SIZE + SIGNATURE_SIZE;
    uint256 constant CAPSULE_FRAG_SIZE = 3 * POINT_SIZE + BIGNUM_SIZE;
    uint256 constant FULL_CAPSULE_FRAG_SIZE = CAPSULE_FRAG_SIZE + CORRECTNESS_PROOF_SIZE;
    uint256 constant PRECOMPUTED_DATA_SIZE = (20 * BIGNUM_SIZE) + 32 + 20 + 5;

    /**
    * @notice Deserialize to capsule (not activated)
    */
    function toCapsule(bytes memory _capsuleBytes)
        internal pure returns (Capsule memory capsule)
    {
        require(_capsuleBytes.length == CAPSULE_SIZE);
        uint256 pointer = getPointer(_capsuleBytes);
        pointer = copyPoint(pointer, capsule.pointE);
        pointer = copyPoint(pointer, capsule.pointV);
        capsule.bnSig = uint256(getBytes32(pointer));
    }

    /**
    * @notice Deserialize to correctness proof
    * @param _pointer Proof bytes memory pointer
    * @param _proofBytesLength Proof bytes length
    */
    function toCorrectnessProof(uint256 _pointer, uint256 _proofBytesLength)
        internal pure returns (CorrectnessProof memory proof)
    {
        require(_proofBytesLength >= CORRECTNESS_PROOF_SIZE);

        _pointer = copyPoint(_pointer, proof.pointE2);
        _pointer = copyPoint(_pointer, proof.pointV2);
        _pointer = copyPoint(_pointer, proof.pointKFragCommitment);
        _pointer = copyPoint(_pointer, proof.pointKFragPok);
        proof.bnSig = uint256(getBytes32(_pointer));
        _pointer += BIGNUM_SIZE;

        proof.kFragSignature = new bytes(SIGNATURE_SIZE);
        // TODO optimize, just two mload->mstore (#1500)
        _pointer = copyBytes(_pointer, proof.kFragSignature, SIGNATURE_SIZE);
        if (_proofBytesLength > CORRECTNESS_PROOF_SIZE) {
            proof.metadata = new bytes(_proofBytesLength - CORRECTNESS_PROOF_SIZE);
            copyBytes(_pointer, proof.metadata, proof.metadata.length);
        }
    }

    /**
    * @notice Deserialize to correctness proof
    */
    function toCorrectnessProof(bytes memory _proofBytes)
        internal pure returns (CorrectnessProof memory proof)
    {
        uint256 pointer = getPointer(_proofBytes);
        return toCorrectnessProof(pointer, _proofBytes.length);
    }

    /**
    * @notice Deserialize to CapsuleFrag
    */
    function toCapsuleFrag(bytes memory _cFragBytes)
        internal pure returns (CapsuleFrag memory cFrag)
    {
        uint256 cFragBytesLength = _cFragBytes.length;
        require(cFragBytesLength >= FULL_CAPSULE_FRAG_SIZE);

        uint256 pointer = getPointer(_cFragBytes);
        pointer = copyPoint(pointer, cFrag.pointE1);
        pointer = copyPoint(pointer, cFrag.pointV1);
        cFrag.kFragId = getBytes32(pointer);
        pointer += BIGNUM_SIZE;
        pointer = copyPoint(pointer, cFrag.pointPrecursor);

        cFrag.proof = toCorrectnessProof(pointer, cFragBytesLength - CAPSULE_FRAG_SIZE);
    }

    /**
    * @notice Deserialize to precomputed data
    */
    function toPreComputedData(bytes memory _preComputedData)
        internal pure returns (PreComputedData memory data)
    {
        require(_preComputedData.length == PRECOMPUTED_DATA_SIZE);
        uint256 initial_pointer = getPointer(_preComputedData);
        uint256 pointer = initial_pointer;

        data.pointEyCoord = uint256(getBytes32(pointer));
        pointer += BIGNUM_SIZE;

        data.pointEZxCoord = uint256(getBytes32(pointer));
        pointer += BIGNUM_SIZE;

        data.pointEZyCoord = uint256(getBytes32(pointer));
        pointer += BIGNUM_SIZE;

        data.pointE1yCoord = uint256(getBytes32(pointer));
        pointer += BIGNUM_SIZE;

        data.pointE1HxCoord = uint256(getBytes32(pointer));
        pointer += BIGNUM_SIZE;

        data.pointE1HyCoord = uint256(getBytes32(pointer));
        pointer += BIGNUM_SIZE;

        data.pointE2yCoord = uint256(getBytes32(pointer));
        pointer += BIGNUM_SIZE;

        data.pointVyCoord = uint256(getBytes32(pointer));
        pointer += BIGNUM_SIZE;

        data.pointVZxCoord = uint256(getBytes32(pointer));
        pointer += BIGNUM_SIZE;

        data.pointVZyCoord = uint256(getBytes32(pointer));
        pointer += BIGNUM_SIZE;

        data.pointV1yCoord = uint256(getBytes32(pointer));
        pointer += BIGNUM_SIZE;

        data.pointV1HxCoord = uint256(getBytes32(pointer));
        pointer += BIGNUM_SIZE;

        data.pointV1HyCoord = uint256(getBytes32(pointer));
        pointer += BIGNUM_SIZE;

        data.pointV2yCoord = uint256(getBytes32(pointer));
        pointer += BIGNUM_SIZE;

        data.pointUZxCoord = uint256(getBytes32(pointer));
        pointer += BIGNUM_SIZE;

        data.pointUZyCoord = uint256(getBytes32(pointer));
        pointer += BIGNUM_SIZE;

        data.pointU1yCoord = uint256(getBytes32(pointer));
        pointer += BIGNUM_SIZE;

        data.pointU1HxCoord = uint256(getBytes32(pointer));
        pointer += BIGNUM_SIZE;

        data.pointU1HyCoord = uint256(getBytes32(pointer));
        pointer += BIGNUM_SIZE;

        data.pointU2yCoord = uint256(getBytes32(pointer));
        pointer += BIGNUM_SIZE;

        data.hashedKFragValidityMessage = getBytes32(pointer);
        pointer += 32;

        data.alicesKeyAsAddress = address(bytes20(getBytes32(pointer)));
        pointer += 20;

        // Lost bytes: a bytes5 variable holding the following byte values:
        //     0: kfrag signature recovery value v
        //     1: cfrag signature recovery value v
        //     2: metadata signature recovery value v
        //     3: specification signature recovery value v
        //     4: ursula pubkey sign byte
        data.lostBytes = bytes5(getBytes32(pointer));
        pointer += 5;

        require(pointer == initial_pointer + PRECOMPUTED_DATA_SIZE);
    }

    // TODO extract to external library if needed (#1500)
    /**
    * @notice Get the memory pointer for start of array
    */
    function getPointer(bytes memory _bytes) internal pure returns (uint256 pointer) {
        assembly {
            pointer := add(_bytes, 32) // skip array length
        }
    }

    /**
    * @notice Copy point data from memory in the pointer position
    */
    function copyPoint(uint256 _pointer, Point memory _point)
        internal pure returns (uint256 resultPointer)
    {
        // TODO optimize, copy to point memory directly (#1500)
        uint8 temp;
        uint256 xCoord;
        assembly {
            temp := byte(0, mload(_pointer))
            xCoord := mload(add(_pointer, 1))
        }
        _point.sign = temp;
        _point.xCoord = xCoord;
        resultPointer = _pointer + POINT_SIZE;
    }

    /**
    * @notice Read 1 byte from memory in the pointer position
    */
    function getByte(uint256 _pointer) internal pure returns (byte result) {
        bytes32 word;
        assembly {
            word := mload(_pointer)
        }
        result = word[0];
        return result;
    }

    /**
    * @notice Read 32 bytes from memory in the pointer position
    */
    function getBytes32(uint256 _pointer) internal pure returns (bytes32 result) {
        assembly {
            result := mload(_pointer)
        }
    }

    /**
    * @notice Copy bytes from the source pointer to the target array
    * @dev Assumes that enough memory has been allocated to store in target.
    * Also assumes that '_target' was the last thing that was allocated
    * @param _bytesPointer Source memory pointer
    * @param _target Target array
    * @param _bytesLength Number of bytes to copy
    */
    function copyBytes(uint256 _bytesPointer, bytes memory _target, uint256 _bytesLength)
        internal
        pure
        returns (uint256 resultPointer)
    {
        // Exploiting the fact that '_target' was the last thing to be allocated,
        // we can write entire words, and just overwrite any excess.
        assembly {
            // evm operations on words
            let words := div(add(_bytesLength, 31), 32)
            let source := _bytesPointer
            let destination := add(_target, 32)
            for
                { let i := 0 } // start at arr + 32 -> first byte corresponds to length
                lt(i, words)
                { i := add(i, 1) }
            {
                let offset := mul(i, 32)
                mstore(add(destination, offset), mload(add(source, offset)))
            }
            mstore(add(_target, add(32, mload(_target))), 0)
        }
        resultPointer = _bytesPointer + _bytesLength;
    }

}
