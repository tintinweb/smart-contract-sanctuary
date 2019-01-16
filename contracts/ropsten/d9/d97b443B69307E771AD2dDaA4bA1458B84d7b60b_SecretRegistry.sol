pragma solidity ^0.4.23;

/// @title SecretRegistry
/// @notice SecretRegistry contract for registering secrets from Raiden Network
/// clients.
contract SecretRegistry {

    string constant public contract_version = "0.4.0";

    // keccak256(secret) => block number at which the secret was revealed
    mapping(bytes32 => uint256) private secrethash_to_block;

    event SecretRevealed(bytes32 indexed secrethash, bytes32 secret);

    /// @notice Registers a hash time lock secret and saves the block number.
    /// This allows the lock to be unlocked after the expiration block.
    /// @param secret The secret used to lock the hash time lock.
    /// @return true if secret was registered, false if the secret was already
    /// registered.
    function registerSecret(bytes32 secret) public returns (bool) {
        bytes32 secrethash = keccak256(abi.encodePacked(secret));
        if (secret == bytes32(0x0) || secrethash_to_block[secrethash] > 0) {
            return false;
        }
        secrethash_to_block[secrethash] = block.number;
        emit SecretRevealed(secrethash, secret);
        return true;
    }

    /// @notice Registers multiple hash time lock secrets and saves the block
    /// number.
    /// @param secrets The array of secrets to be registered.
    /// @return true if all secrets could be registered, false otherwise.
    function registerSecretBatch(bytes32[] secrets) public returns (bool) {
        bool completeSuccess = true;
        for(uint i = 0; i < secrets.length; i++) {
            if(!registerSecret(secrets[i])) {
                completeSuccess = false;
            }
        }
        return completeSuccess;
    }

    /// @notice Get the stored block number at which the secret was revealed.
    /// @param secrethash The hash of the registered secret `keccak256(secret)`.
    /// @return The block number at which the secret was revealed.
    function getSecretRevealBlockHeight(bytes32 secrethash) public view returns (uint256) {
        return secrethash_to_block[secrethash];
    }
}