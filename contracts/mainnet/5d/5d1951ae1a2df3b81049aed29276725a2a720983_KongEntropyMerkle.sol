/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

pragma solidity 0.5.17;

/**
 * @title Interface for EllipticCurve contract.
 */
interface EllipticCurveInterface {

    function validateSignature(bytes32 message, uint[2] calldata rs, uint[2] calldata Q) external view returns (bool);

}

/**
 * @title Interface for Register contract.
 */
interface RegisterInterface {

  function isDeviceMintable(bytes32 hardwareHash) external view returns (bool);
  function getRootDetails(bytes32 root) external view returns (uint256, uint256, uint256, uint256, string memory, string memory, uint256, uint256);
  function mintKong(bytes32[] calldata proof, bytes32 root, bytes32 hardwareHash, address recipient) external;

}

/**
 * @title Kong Entropy Contract.
 *
 * @dev   This contract can be presented with signatures for public keys registered in the
 *        `Register` contract. The function `submitEntropy()` verifies the validity of the
 *        signature using the remotely deployed `EllipticCurve` contract. If the signature
 *        is valid, the contract calls the `mintKong()` function of the `Register` contract
 *        to mint Kong.
 */
contract KongEntropyMerkle {

    // Addresses of the contracts `Register` and `EllipticCurve`.
    address public _regAddress;
    address public _eccAddress;

    // Mapping for minting status of keys.
    mapping(bytes32 => bool) public _mintedKeys;

    // Emits when submitEntropy() is successfully called.
    event Minted(
        bytes32 hardwareHash,
        bytes32 message,
        uint256 r,
        uint256 s
    );

    /**
     * @dev The constructor sets the addresses of the contracts `Register` and `EllipticCurve`.
     *
     * @param eccAddress           The address of the EllipticCurve contract.
     * @param regAddress           The address of the Register contract.
     */
    constructor(address eccAddress, address regAddress) public {

        _eccAddress = eccAddress;
        _regAddress = regAddress;

    }

    /**
     * @dev `submitEntropy()` can be presented with SECP256R1 signatures of public keys registered
     *      in the `Register` contract. When presented with a valid signature in the expected format,
     *      the contract calls the `mintKong()` function of `Register` to mint Kong token to `to`.

     *
     * @param merkleProof             Merkle proof for the device.
     * @param merkleRoot              Merkle root the device belongs to.     
     * @param primaryPublicKeyHash    Hash of the primary public key.
     * @param secondaryPublicKeyHash  Hash of the secondary public key.
     * @param hardwareSerial          Hash of the hardwareSerial number.
     * @param tertiaryPublicKeyX      The x-coordinate of the tertiary public key.
     * @param tertiaryPublicKeyY      The y-coordinate of the tertiary public key.
     * @param to                      Recipient.
     * @param blockNumber             Block number of the signed blockhash.
     * @param rs                      The array containing the r & s values fo the signature.
     */
    function submitEntropy(
        bytes32[] memory merkleProof, 
        bytes32 merkleRoot, 
        bytes32 primaryPublicKeyHash,
        bytes32 secondaryPublicKeyHash,
        bytes32 hardwareSerial,
        uint256 tertiaryPublicKeyX,
        uint256 tertiaryPublicKeyY,
        address to,
        uint256 blockNumber,
        uint256[2] memory rs
    )
        public
    {

        // Hash the provided tertiary key.
        bytes32 hashedKey = sha256(abi.encodePacked(tertiaryPublicKeyX, tertiaryPublicKeyY));

        // Hash all the keys in order to calculate the hardwareHash.
        bytes32 hardwareHash = sha256(abi.encodePacked(primaryPublicKeyHash, secondaryPublicKeyHash, hashedKey, hardwareSerial));

        // Verify that no signature has been submitted before for this key.
        require(_mintedKeys[hardwareHash] == false, 'Already minted.');

        // Check registry to verify if device is mintable.
        require(RegisterInterface(_regAddress).isDeviceMintable(hardwareHash), 'Minted in registry.');

        // Get Kong amount; Divide internal representation by 10 ** 19 for cost scaling; perform work in proportion to scaledKongAmount.
        uint256 kongAmount;
        (kongAmount, , , , , , , ) = RegisterInterface(_regAddress).getRootDetails(merkleRoot);
        for (uint i=0; i < kongAmount / uint(10 ** 19); i++) {
            keccak256(abi.encodePacked(blockhash(block.number)));
        }

        // Validate signature.
        bytes32 messageHash = sha256(abi.encodePacked(to, blockhash(blockNumber)));
        require(_validateSignature(messageHash, rs, tertiaryPublicKeyX, tertiaryPublicKeyY), 'Invalid signature.');

        // Call minting function in Register contract.
        RegisterInterface(_regAddress).mintKong(merkleProof, merkleRoot, hardwareHash, to);

        // Update mapping with minted keys.
        _mintedKeys[hardwareHash] = true;

        // Emit event.
        emit Minted(hardwareHash, messageHash, rs[0], rs[1]);
    }

    /**
     * @dev Function to validate SECP256R1 signatures.
     *
     * @param message           The hash of the signed message.
     * @param rs                R+S value of the signature.
     * @param publicKeyX        X-coordinate of the publicKey.
     * @param publicKeyY        Y-coordinate of the publicKey.
     */
    function _validateSignature(
        bytes32 message,
        uint256[2] memory rs,
        uint256 publicKeyX,
        uint256 publicKeyY
    )
        internal view returns (bool)
    {
        return EllipticCurveInterface(_eccAddress).validateSignature(message, rs, [publicKeyX, publicKeyY]);
    }

    /**
     * @dev Function to check if a given hardwareHash has been minted or not.
     *
     * @param hardwareHash      The hardwareHash of the device.
     */
    function isDeviceMinted(
        bytes32 hardwareHash
    )
        external view returns (bool)
    {
        return _mintedKeys[hardwareHash];
    }

}