// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.2;

import "./ImplMemoryStructure.sol";
import "./ERC721.sol";
import "./MyNFTBridge.sol";


/// @author Guillaume Gonnaud 2021
/// @title ImplMyNFTBridgeFunMigrateFromRC721
/// @notice The well-ordered memory structure of our bridge. Used for generating proper memory address at compilation.
contract ImplMyNFTBridgeFunMigrateFromERC721  is ImplMemoryStructure, MyNFTBridgeERC721toERC721Arrival {

    
    /// @notice Declare a migration of an ERC-721 token from a different bridge toward this bridge as an IOU token.
    /// @dev Throw if msg.sender is not a relay accredited by _destinationWorld Owner
    /// This is especially important as a rogue relay could theoritically release tokens put in escrow beforehand.
    /// This also mean that a token can be migrated back only by a relay accredited by the original token publisher.
    /// Throw if the destination token is already in escrow with this bridge as a migration origin token but that 
    /// current _origin* parameters do not match the previous _destination* parameters : Only the IOU can claim the 
    /// original token back.
    /// @param _originUniverse An array of 32 bytes representing the destination universe. 
    /// eg : "Ropsten", "Moonbeam". Please refer to the documentation for a standardized list of destination.
    /// @param _originBridge An array of 32 bytes representing the origin bridge. If the origin
    /// bridge is on an EVM, it is most likely an address.
    /// @param _originWorld An array of 32 bytes representing the origin world of the origin token. 
    /// If the origin bridge is on an EVM, it is most likely an address.
    /// @param _originTokenId An array of 32 bytes representing the tokenId of the origin token. 
    /// If the origin token is an ERC-721 token in an EVM smart contract, it is most likely an uint256.
    /// @param _originOwner An array of 32 bytes representing the original owner of the migrated token . 
    /// If the origin world is on an EVM, it is most likely an address.
    /// @param _destinationWorld An array of 32 bytes representing the destination world of the migrated token. 
    /// If the destination bridge is on an EVM, it is most likely an address.
    /// @param _destinationTokenId An array of 32 bytes representing the tokenId world of the migrated token. 
    /// If the destination token is an ERC-721 token in an EVM smart contract, it is most likely an uint256.
    /// @param _destinationOwner An array of 32 bytes representing the final owner of the migrated token . 
    /// If the destination world is on an EVM, it is most likely an address.
    /// @param _signee The address that will be verified as signing the transfer as legitimate on the destination
    /// If the owner has access to a private key, it should be the owner.
    /// A relay unable to lie on _signee from the departure bridge to here is a trustless relay
    /// @param _height The height at which the origin token was put in escrow in the origin universe.
    /// Usually the block.timestamp, but different universes have different metrics
    /// @param _relayedMigrationHashSigned The _escrowHash of the origin chain, hashed with the relay public address then signed by _signee
    function migrateFromIOUERC721ToERC721(
        bytes32 _originUniverse,
        bytes32 _originBridge, 
        bytes32 _originWorld, 
        bytes32 _originTokenId, 
        bytes32 _originOwner, 
        address _destinationWorld,
        uint256 _destinationTokenId,
        address _destinationOwner,
        address _signee,
        bytes32 _height,
        bytes calldata _relayedMigrationHashSigned
    ) external override {
        
        //Reconstruct the escrow hash
        bytes32 escrowHash = generateMigrationHashArtificialLocalIOUIncoming(
                _originUniverse,
                _originBridge,
                _originWorld,
                _originTokenId,
                _originOwner,
                _destinationWorld,
                _destinationTokenId,
                _destinationOwner,
                _signee,
                _height
        );

        //Check that the escrow hash have been legitimately signed for this relay
        checkEscrowSignature(_signee, escrowHash, _relayedMigrationHashSigned);

        //Try to get the current token owner
        try ERC721(_destinationWorld).ownerOf(_destinationTokenId) returns (address _currOwner) {
            if(_currOwner == address(0x0)){
                // If the current token owner is 0, then the token is not strict ERC721 compliant BUT 
                // the bridge should still be able to transfer it for the purpose of minting
                ERC721(_destinationWorld).safeTransferFrom(address(0x0), _destinationOwner, _destinationTokenId);

            } else if (_currOwner == address(this)){ 
                // If the current token owner is the bridge, then the token was in escrow with us
                // This mean that project creators and owners need to trust the relays to not move 
                // the tokens prematurely while the represented NFT are on an another chain.
                ERC721(_destinationWorld).safeTransferFrom(_currOwner, _destinationOwner, _destinationTokenId);
            }
        } catch {
            // The bridge assume that the call failed because the _destinationWorld is ERC-721 compliant and the token has not been minted yet
            // The call of Safetransfer by the bridge will henceforth mint the IOU token
            ERC721(_destinationWorld).safeTransferFrom(address(0x0), _destinationOwner, _destinationTokenId);
        }
    }


    /// @notice Declare a migration of an ERC-721 token from a different bridge toward this bridge as a full migration
    /// @dev Throw if msg.sender is not a relay accredited by _destinationWorld Owner
    /// This is especially important as a rogue relay could theoritically release tokens put in escrow beforehand.
    /// This also mean that a token can be migrated back only by a relay accredited by the original token publisher.
    /// Contrary to IOU migrations, do not throw in case of mismatched token back and forth migration. 
    /// @param _originUniverse An array of 32 bytes representing the destination universe. 
    /// eg : "Ropsten", "Moonbeam". Please refer to the documentation for a standardized list of destination.
    /// @param _originBridge An array of 32 bytes representing the origin bridge. If the origin
    /// bridge is on an EVM, it is most likely an address.
    /// @param _originWorld An array of 32 bytes representing the origin world of the origin token. 
    /// If the origin bridge is on an EVM, it is most likely an address.
    /// @param _originTokenId An array of 32 bytes representing the tokenId of the origin token. 
    /// If the origin token is an ERC-721 token in an EVM smart contract, it is most likely an uint256.
    /// @param _originOwner An array of 32 bytes representing the original owner of the migrated token . 
    /// If the origin world is on an EVM, it is most likely an address.
    /// @param _destinationWorld An array of 32 bytes representing the destination world of the migrated token. 
    /// If the destination bridge is on an EVM, it is most likely an address.
    /// @param _destinationTokenId An array of 32 bytes representing the tokenId world of the migrated token. 
    /// If the destination token is an ERC-721 token in an EVM smart contract, it is most likely an uint256.
    /// @param _destinationOwner An array of 32 bytes representing the final owner of the migrated token . 
    /// If the destination world is on an EVM, it is most likely an address.
    /// @param _signee The address that will be verified as signing the transfer as legitimate on the destination
    /// If the owner has access to a private key, it should be the owner.
    /// A relay unable to lie on _signee from the departure bridge to here is a trustless relay
    /// @param _height The height at which the origin token was put in escrow in the origin universe.
    /// Usually the block.timestamp, but different universes have different metrics
    /// @param _relayedMigrationHashSigned The _escrowHash of the origin chain appended with the relay public address then signed by _signee
    function migrateFromFullERC721ToERC721(
        bytes32 _originUniverse,
        bytes32 _originBridge, 
        bytes32 _originWorld, 
        bytes32 _originTokenId, 
        bytes32 _originOwner, 
        address _destinationWorld,
        uint256 _destinationTokenId,
        address _destinationOwner,
        address _signee,
        bytes32 _height,
        bytes calldata _relayedMigrationHashSigned
    ) external override {

    }



    //Generate a migration hash for an incoming IOU migration
    function generateMigrationHashArtificialLocalIOUIncoming(   
        bytes32 _originUniverse, 
        bytes32 _originBridge,
        bytes32 _originWorld, 
        bytes32 _originTokenId, 
        bytes32 _originOwner,
        address _destinationWorld,
        uint256 _destinationTokenId,
        address _destinationOwner,
        address _signee,
        bytes32 _height
    ) internal view returns(bytes32){
        return generateMigrationHashArtificial(
            true,     
            _originUniverse, 
            _originBridge,
            _originWorld,  
            _originTokenId, 
            _originOwner,
            localUniverse,
            bytes32(uint(uint160(address(this)))),
            bytes32(uint(uint160(_destinationWorld))), 
            bytes32(_destinationTokenId),
            bytes32(uint(uint160(_destinationOwner))),
            bytes32(uint(uint160(_signee))),
            _height
        );
    }


    //Generate a migration hash
    function generateMigrationHashArtificial(   
        bool _isIOU,     
        bytes32 _originUniverse, 
        bytes32 _originBridge,
        bytes32 _originWorld, 
        bytes32 _originTokenId, 
        bytes32 _originOwner,
        bytes32 _destinationUniverse,
        bytes32 _destinationBridge,
        bytes32 _destinationWorld,
        bytes32 _destinationTokenId,
        bytes32 _destinationOwner,
        bytes32 _signee,
        bytes32 _originHeight
    ) internal pure returns(bytes32) {
            return keccak256(
                abi.encodePacked(
                    _isIOU,
                    _originUniverse, 
                    _originBridge,
                    _originWorld, 
                    _originTokenId,
                    _originOwner,
                    _destinationUniverse, 
                    _destinationBridge, 
                    _destinationWorld, 
                    _destinationTokenId,
                    _destinationOwner,
                    _signee,
                    _originHeight
                )
            );
    }

/// TODO : Change to sign V4, see implementation in gasless cryptograph
    function checkEscrowSignature(
        address _signee,
        bytes32 escrowHash,
        bytes calldata _relayedMigrationHashSigned
    ) internal view {
        //Generate the message that was outputed by eth_sign
        bytes32 message = prefixed(keccak256(abi.encodePacked(escrowHash, msg.sender))); //The escrowHash emitted by the departure bridge is hashed with the current relay public address
        require(recoverSigner(message, _relayedMigrationHashSigned) == _signee, "The migration data signed by the signee do not match the inputed data");
    }

    /// signature methods.
    function splitSignature(bytes memory sig) internal pure returns (uint8 v, bytes32 r, bytes32 s) {

        require(sig.length == 65);
        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }
        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    /// builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

}