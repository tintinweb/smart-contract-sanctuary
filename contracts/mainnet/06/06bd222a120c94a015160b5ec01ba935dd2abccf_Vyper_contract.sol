# @version ^0.2.0
# (c) Copyright Origin Protocol, Inc, 2021

"""
@title NFT Swap contract for LetMeGet.io
@license MIT
@author Mike Shultz <[email protected]>
"""

from vyper.interfaces import ERC721


###
## Events
###


event Offer:
    wanted_owner: indexed(address)
    wanted_contract: indexed(address)
    offer_contract: indexed(address)
    wanted_token_id: uint256
    offer_token_id: uint256

event OfferRevoked:
    wanted_owner: indexed(address)
    wanted_contract: indexed(address)
    offer_contract: indexed(address)
    wanted_token_id: uint256
    offer_token_id: uint256

event Accept:
    offer_owner: indexed(address)
    wanted_contract: indexed(address)
    offer_contract: indexed(address)
    wanted_token_id: uint256
    offer_token_id: uint256


###
## Structs
###


struct OfferDetails:
    revoked: bool
    signer: address
    signature: Bytes[65]


###
## Constants and storage
###


VERSION: constant(uint256) = 1
PREFIX: constant(Bytes[28]) = b"\x19Ethereum Signed Message:\n32"

# Holds details about offers
offers: public(HashMap[bytes32, OfferDetails])


###
## Utilities
###


@internal
@pure
def _prefix_hash(hash: bytes32) -> Bytes[65]:
    """
    @dev Prefix a hash with the "standard" Ethereum Signed Message prefix
    @param hash to prefix
    @return Byte array of prefixed hash
    """
    return concat(PREFIX, hash)


@internal
@pure
def _recover(prefixed_hash: bytes32, signature: Bytes[65]) -> address:
    """
    @dev Recover signing account address, given data and signature
    @param prefixed_hash is hash of prefixed data
    @param signature to recover
    @return address of signer (or random-ish address)
    """
    r: uint256 = convert(slice(signature, 0, 32), uint256)
    s: uint256 = convert(slice(signature, 32, 32), uint256)
    v: uint256 = convert(slice(signature, 64, 1), uint256)

    return ecrecover(prefixed_hash, v, r, s)


@internal
@pure
def _hash_params(
    offer_contract: address,
    offer_token_id: uint256,
    wanted_contract: address,
    wanted_token_id: uint256,
) -> bytes32:
    """
    @dev Pack and hash the given offer paramters
    @param offer_contract Contract address for the offered token
    @param offer_token_id Token ID for the offered token
    @param wanted_contract Contract address for the wanted token
    @param wanted_token_id Token ID for the wanted token
    @return Hash of the given params
    """
    return keccak256(
        concat(
            convert(offer_contract, bytes32),
            convert(offer_token_id, bytes32),
            convert(wanted_contract, bytes32),
            convert(wanted_token_id, bytes32)
        )
    )


###
## Internals
###


@internal
@view
def _offer_exists(
    offer_contract: address,
    offer_token_id: uint256,
    wanted_contract: address,
    wanted_token_id: uint256
) -> bool:
    """
    @dev Check if an offer has been made and is alive
    @param offer_contract Contract address for the offered token
    @param offer_token_id Token ID for the offered token
    @param wanted_contract Contract address for the wanted token
    @param wanted_token_id Token ID for the wanted token
    @return True if the offer exists
    """
    param_hash: bytes32 = self._hash_params(
        offer_contract,
        offer_token_id,
        wanted_contract,
        wanted_token_id
    )
    return self.offers[param_hash].signer != empty(address)


@internal
@view
def _offer_revoked(
    offer_contract: address,
    offer_token_id: uint256,
    wanted_contract: address,
    wanted_token_id: uint256
) -> bool:
    """
    @dev Check if an offer has been revoked
    @param offer_contract Contract address for the offered token
    @param offer_token_id Token ID for the offered token
    @param wanted_contract Contract address for the wanted token
    @param wanted_token_id Token ID for the wanted token
    @return True if the offer has been revoked
    """
    param_hash: bytes32 = self._hash_params(
        offer_contract,
        offer_token_id,
        wanted_contract,
        wanted_token_id
    )
    return self.offers[param_hash].revoked


@internal
@view
def _signer(
    offer_contract: address,
    offer_token_id: uint256,
    wanted_contract: address,
    wanted_token_id: uint256,
    signature: Bytes[65]
) -> (address, bytes32):
    """
    @dev Get signing account for signature given offer params
    @param offer_contract Contract address for the offered token
    @param offer_token_id Token ID for the offered token
    @param wanted_contract Contract address for the wanted token
    @param wanted_token_id Token ID for the wanted token
    @param signature to recover
    @return address of the signer
    """
    param_hash: bytes32 = self._hash_params(
        offer_contract,
        offer_token_id,
        wanted_contract,
        wanted_token_id
    )
    msg_hash: bytes32 = keccak256(self._prefix_hash(param_hash))
    return self._recover(msg_hash, signature), param_hash


@internal
@view
def _data_signer(
    data: bytes32,
    signature: Bytes[65]
) -> address:
    """
    @dev Get signing account for signature given bytes32 data
    @param data that was signed
    @param signature to recover
    @return address of the signer
    """
    p_hash: bytes32 = keccak256(self._prefix_hash(data))
    return self._recover(p_hash, signature)


###
## Externals
###


@external
@view
def version() -> uint256:
    """
    @dev Version getter
    @return Version of the LMG contract
    """
    return VERSION


@external
@view
def prefix_hash(hash: bytes32) -> Bytes[65]:
    """
    @dev Prefix a hash with the "standard" Ethereum signed message prefix
    @param hash to prefix
    @return Prefixed bytes ready to be hashed
    """
    return self._prefix_hash(hash)


@external
@view
def hash_params(
    offer_contract: address,
    offer_token_id: uint256,
    wanted_contract: address,
    wanted_token_id: uint256,
) -> bytes32:
    """
    @dev Hash given parameters
    @param offer_contract Contract address for the offered token
    @param offer_token_id Token ID for the offered token
    @param wanted_contract Contract address for the wanted token
    @param wanted_token_id Token ID for the wanted token
    @return keccak hash of packed parameters
    """
    return self._hash_params(
        offer_contract,
        offer_token_id,
        wanted_contract,
        wanted_token_id
    )


@external
@view
def offer_can_complete(
    offer_contract: address,
    offer_token_id: uint256,
    wanted_contract: address,
    wanted_token_id: uint256,
) -> bool:
    """
    @dev Check if an offer should complete if accepted
    @param offer_contract Contract address for the offered token
    @param offer_token_id Token ID for the offered token
    @param wanted_contract Contract address for the wanted token
    @param wanted_token_id Token ID for the wanted token
    @return True if the offer can complete
    """
    return (
        not self._offer_revoked(
            offer_contract,
            offer_token_id,
            wanted_contract,
            wanted_token_id
        ) and
        ERC721(offer_contract).getApproved(offer_token_id) == self and
        ERC721(wanted_contract).getApproved(wanted_token_id) == self
    )


@external
@view
def offer_exists(
    offer_contract: address,
    offer_token_id: uint256,
    wanted_contract: address,
    wanted_token_id: uint256
) -> bool:
    """
    @dev Check if an offer has been made and is alive
    @param offer_contract Contract address for the offered token
    @param offer_token_id Token ID for the offered token
    @param wanted_contract Contract address for the wanted token
    @param wanted_token_id Token ID for the wanted token
    @return True if the offer exists
    """
    return self._offer_exists(
        offer_contract,
        offer_token_id,
        wanted_contract,
        wanted_token_id
    )


@external
@view
def offer_revoked(
    offer_contract: address,
    offer_token_id: uint256,
    wanted_contract: address,
    wanted_token_id: uint256
) -> bool:
    """
    @dev Check if an offer has been revoked
    @param offer_contract Contract address for the offered token
    @param offer_token_id Token ID for the offered token
    @param wanted_contract Contract address for the wanted token
    @param wanted_token_id Token ID for the wanted token
    @return True if the offer has been revoked
    """
    return self._offer_revoked(
        offer_contract,
        offer_token_id,
        wanted_contract,
        wanted_token_id
    )


@external
@view
def offer_signer(
    offer_contract: address,
    offer_token_id: uint256,
    wanted_contract: address,
    wanted_token_id: uint256,
    signature: Bytes[65]
) -> (address, bytes32):
    """
    @dev Get the signing account for the given offer params and signature
    @param offer_contract Contract address for the offered token
    @param offer_token_id Token ID for the offered token
    @param wanted_contract Contract address for the wanted token
    @param wanted_token_id Token ID for the wanted token
    @param signature Signature of the offer data
    """
    return self._signer(
        offer_contract,
        offer_token_id,
        wanted_contract,
        wanted_token_id,
        signature
    )


@external
@nonreentrant('offer')
def offer(
    offer_contract: address,
    offer_token_id: uint256,
    wanted_contract: address,
    wanted_token_id: uint256,
    signature: Bytes[65],
):
    """
    @dev Offer a token for a wanted token
    @param offer_contract Contract address for the offered token
    @param offer_token_id Token ID for the offered token
    @param wanted_contract Contract address for the wanted token
    @param wanted_token_id Token ID for the wanted token
    @param signature Offerer's signature of the offer data
    """
    signer: address = empty(address)
    param_hash: bytes32 = empty(bytes32)

    signer, param_hash = self._signer(
        offer_contract,
        offer_token_id,
        wanted_contract,
        wanted_token_id,
        signature
    )

    assert wanted_contract != empty(address), "no-wanted-contract"

    wanted_owner: address = ERC721(wanted_contract).ownerOf(wanted_token_id)

    assert wanted_owner != empty(address), "no-wanted-owner"
    assert self.offers[param_hash].signer == empty(address), "offer-exists"
    assert not self.offers[param_hash].revoked, "offer-revoked"
    assert signer == ERC721(offer_contract).ownerOf(offer_token_id), "signer-not-owner"
    assert self == ERC721(offer_contract).getApproved(offer_token_id), "contract-not-approved"

    self.offers[param_hash].signer = signer
    self.offers[param_hash].signature = signature

    log Offer(
        wanted_owner,
        wanted_contract,
        offer_contract,
        wanted_token_id,
        offer_token_id
    )


@external
@nonreentrant('revoke')
def revoke(
    offer_contract: address,
    offer_token_id: uint256,
    wanted_contract: address,
    wanted_token_id: uint256,
    signature: Bytes[65],
):
    """
    @notice This can not be undone!
    @dev Revoke a previous offer preventing it from being executed.
    @param offer_contract Contract address for the offered token
    @param offer_token_id Token ID for the offered token
    @param wanted_contract Contract address for the wanted token
    @param wanted_token_id Token ID for the wanted token
    @param signature Offerer's signature of the offer signature
    """
    signer: address = empty(address)
    param_hash: bytes32 = self._hash_params(
        offer_contract,
        offer_token_id,
        wanted_contract,
        wanted_token_id
    )

    assert self.offers[param_hash].signer != empty(address), "offer-does-not-exist"

    # To revoke an offer, signer must sign the hash of the original signature
    signer = self._data_signer(
        keccak256(self.offers[param_hash].signature),
        signature
    )

    assert self.offers[param_hash].signer != signer, "not-maker"

    wanted_owner: address = ERC721(wanted_contract).ownerOf(wanted_token_id)

    self.offers[param_hash].revoked = True

    log OfferRevoked(
        wanted_owner,
        wanted_contract,
        offer_contract,
        wanted_token_id,
        offer_token_id
    )


@external
@nonreentrant('accept')
def accept(
    offer_contract: address,
    offer_token_id: uint256,
    wanted_contract: address,
    wanted_token_id: uint256,
    signature: Bytes[65],
):
    """
    @dev Accept an offer to trade the offered token for a wanted token
    @param offer_contract Contract address for the offered token
    @param offer_token_id Token ID for the offered token
    @param wanted_contract Contract address for the wanted token
    @param wanted_token_id Token ID for the wanted token
    @param signature Wanted token owner's signature of the offer data
    """
    signer: address = empty(address)
    param_hash: bytes32 = empty(bytes32)

    signer, param_hash = self._signer(
        offer_contract,
        offer_token_id,
        wanted_contract,
        wanted_token_id,
        signature
    )

    assert self.offers[param_hash].signer != empty(address), "offer-does-not-exist"
    assert not self.offers[param_hash].revoked, "offer-revoked"
    assert signer == ERC721(wanted_contract).ownerOf(wanted_token_id), "signer-not-owner"
    assert self == ERC721(wanted_contract).getApproved(wanted_token_id), "contract-not-approved"

    offer_owner: address = self.offers[param_hash].signer

    # Remove the offer record
    self.offers[param_hash] = empty(OfferDetails)

    # Transfer the offered token
    ERC721(offer_contract).safeTransferFrom(
        offer_owner,
        signer,
        offer_token_id,
        empty(Bytes[1])
    )

    # Transfer the wanted token
    ERC721(wanted_contract).safeTransferFrom(
        signer,
        offer_owner,
        wanted_token_id,
        empty(Bytes[1])
    )

    log Accept(
        offer_owner,
        wanted_contract,
        offer_contract,
        wanted_token_id,
        offer_token_id
    )