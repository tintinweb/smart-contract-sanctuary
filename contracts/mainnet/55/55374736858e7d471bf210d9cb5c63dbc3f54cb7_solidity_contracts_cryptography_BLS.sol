pragma solidity 0.5.17;

import "./AltBn128.sol";


/**
 * @title BLS signatures verification
 * @dev Library for verification of 2-pairing-check BLS signatures, including
 * basic, aggregated, or reconstructed threshold BLS signatures, generated
 * using the AltBn128 curve.
 */
library BLS {

    /**
     * @dev Creates a signature over message using the provided secret key.
     */
    function sign(bytes memory message, uint256 secretKey) public view returns(bytes memory) {
        AltBn128.G1Point memory p_1 = AltBn128.g1HashToPoint(message);
        AltBn128.G1Point memory p_2 = AltBn128.scalarMultiply(p_1, secretKey);

        return AltBn128.g1Marshal(p_2);
    }

    /**
     * @dev Verify performs the pairing operation to check if the signature
     * is correct for the provided message and the corresponding public key.
     * Public key must be a valid point on G2 curve in an uncompressed format.
     * Message must be a valid point on G1 curve in an uncompressed format.
     * Signature must be a valid point on G1 curve in an uncompressed format.
     */
    function verify(
        bytes memory publicKey,
        bytes memory message,
        bytes memory signature
    ) public view returns (bool) {

        AltBn128.G1Point memory _signature = AltBn128.g1Unmarshal(signature);

        return AltBn128.pairing(
            AltBn128.G1Point(_signature.x, AltBn128.getP() - _signature.y),
            AltBn128.g2(),
            AltBn128.g1Unmarshal(message),
            AltBn128.g2Unmarshal(publicKey)
        );
    }

    /**
     * @dev VerifyBytes wraps the functionality of BLS.verify, but hashes a message
     * to a point on G1 and marshal to bytes first to allow raw bytes verificaion.
     */
    function verifyBytes(
        bytes memory publicKey,
        bytes memory message,
        bytes memory signature
    ) public view returns (bool) {
        AltBn128.G1Point memory point = AltBn128.g1HashToPoint(message);
        bytes memory messageAsPoint = AltBn128.g1Marshal(point);

        return verify(publicKey, messageAsPoint, signature);
    }
}
