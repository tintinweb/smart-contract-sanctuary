pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./libs.sol";
import "./Roles.sol";
import "./ERC721.sol";

/**
 * @title MintableOwnableToken
 * @dev anyone can mint token.
 */
contract MintableOwnableToken is Ownable, ERC721, IERC721Metadata, ERC721Burnable, ERC721Base, SignerRole {

    /// @notice Token minting event.
    event CreateERC721_v4(address indexed creator, string name, string symbol);

    /// @notice The contract constructor.
    /// @param name - The value for the `name`.
    /// @param symbol - The value for the `symbol`.
    /// @param contractURI - The URI with contract metadata.
    ///        The metadata should be a JSON object with fields: `id, name, description, image, external_link`.
    ///        If the URI containts `{address}` template in its body, then the template must be substituted with the contract address.
    /// @param tokenURIPrefix - The URI prefix for all the tokens. Usually set to ipfs gateway.
    /// @param signer - The address of the initial signer.
    constructor (string memory name, string memory symbol, string memory contractURI, string memory tokenURIPrefix, address signer) public ERC721Base(name, symbol, contractURI, tokenURIPrefix) {
        emit CreateERC721_v4(msg.sender, name, symbol);
        _addSigner(signer);
        _registerInterface(bytes4(keccak256('MINT_WITH_ADDRESS')));
    }

    /// @notice The function for token minting. It creates a new token.
    ///         Must contain the signature of the format: `sha3(tokenContract.address.toLowerCase() + tokenId)`.
    ///         Where `tokenContract.address` is the address of the contract and tokenId is the id in uint256 hex format.
    ///         0 as uint256 must look like this: `0000000000000000000000000000000000000000000000000000000000000000`.
    ///         The message **must not contain** the standard prefix.
    /// @param tokenId - The id of a new token.
    /// @param v - v parameter of the ECDSA signature.
    /// @param r - r parameter of the ECDSA signature.
    /// @param s - s parameter of the ECDSA signature.
    /// @param _fees - An array of the secondary fees for this token.
    /// @param tokenURI - The suffix with `tokenURIPrefix` usually complements ipfs link to metadata object.
    ///        The URI must link to JSON object with various fields: `name, description, image, external_url, attributes`.
    ///        Can also contain another various fields.
    function mint(uint256 tokenId, uint8 v, bytes32 r, bytes32 s, Fee[] memory _fees, string memory tokenURI) public {
        require(isSigner(ecrecover(keccak256(abi.encodePacked(this, tokenId)), v, r, s)), "signer should sign tokenId");
        _mint(msg.sender, tokenId, _fees);
        _setTokenURI(tokenId, tokenURI);
    }

    /// @notice This function can be called by the contract owner and it adds an address as a new signer.
    ///         The signer will authorize token minting by signing token ids.
    /// @param account - The address of a new signer.
    function addSigner(address account) public onlyOwner {
        _addSigner(account);
    }

    /// @notice This function can be called by the contract owner and it removes an address from signers pool.
    /// @param account - The address of a signer to remove.
    function removeSigner(address account) public onlyOwner {
        _removeSigner(account);
    }


    /// @notice Sets the URI prefix for all tokens.
    function setTokenURIPrefix(string memory tokenURIPrefix) public onlyOwner {
        _setTokenURIPrefix(tokenURIPrefix);
    }


    /// @notice Sets the URI for the contract metadata.
    function setContractURI(string memory contractURI) public onlyOwner {
        _setContractURI(contractURI);
    }
}

/**
 * @title MintableUserToken
 * @dev Only owner can mint tokens.
 */
contract MintableUserToken is MintableOwnableToken {
    /// @notice The contract constructor.
    /// @param name - The value for the `name`.
    /// @param symbol - The value for the `symbol`.
    /// @param contractURI - The URI with contract metadata.
    ///        The metadata should be a JSON object with fields: `id, name, description, image, external_link`.
    ///        If the URI containts `{address}` template in its body, then the template must be substituted with the contract address.
    /// @param tokenURIPrefix - The URI prefix for all the tokens. Usually set to ipfs gateway.
    /// @param signer - The address of the initial signer.
    constructor(string memory name, string memory symbol, string memory contractURI, string memory tokenURIPrefix, address signer) MintableOwnableToken(name, symbol, contractURI, tokenURIPrefix, signer) public {}

    /// @notice The function for token minting. It creates a new token. Can be called only by the contract owner.
    ///         Must contain the signature of the format: `sha3(tokenContract.address.toLowerCase() + tokenId)`.
    ///         Where `tokenContract.address` is the address of the contract and tokenId is the id in uint256 hex format.
    ///         0 as uint256 must look like this: `0000000000000000000000000000000000000000000000000000000000000000`.
    ///         The message **must not contain** the standard prefix.
    /// @param tokenId - The id of a new token.
    /// @param v - v parameter of the ECDSA signature.
    /// @param r - r parameter of the ECDSA signature.
    /// @param s - s parameter of the ECDSA signature.
    /// @param _fees - An array of the secondary fees for this token.
    /// @param tokenURI - The suffix with `tokenURIPrefix` usually complements ipfs link to metadata object.
    ///        The URI must link to JSON object with various fields: `name, description, image, external_url, attributes`.
    ///        Can also contain another various fields.
    function mint(uint256 tokenId, uint8 v, bytes32 r, bytes32 s, Fee[] memory _fees, string memory tokenURI) onlyOwner public {
        super.mint(tokenId, v, r, s, _fees, tokenURI);
    }
}