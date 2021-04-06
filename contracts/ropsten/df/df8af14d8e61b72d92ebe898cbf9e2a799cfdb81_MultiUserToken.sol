pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./ERC1155.sol";

/// @title MultiToken
/// @notice ERC1155 token contract with the support of secondary fees.
contract MultiToken is Ownable, SignerRole, ERC1155Base {
    /// @notice Tokens name;
    string public name;
    /// @notice Tokens symbol.
    string public symbol;

    /// @notice The contract constructor.
    /// @param _name - The value for the `name`.
    /// @param _symbol - The value for the `symbol`.
    /// @param signer - The address of the initial signer.
    /// @param contractURI - The URI with contract metadata.
    ///        The metadata should be a JSON object with fields: `id, name, description, image, external_link`.
    ///        If the URI containts `{address}` template in its body, then the template must be substituted with the contract address.
    /// @param tokenURIPrefix - The URI prefix for all the tokens. Usually set to ipfs gateway.
    constructor(string memory _name, string memory _symbol, address signer, string memory contractURI, string memory tokenURIPrefix) ERC1155Base(contractURI, tokenURIPrefix) public {
        name = _name;
        symbol = _symbol;

        _addSigner(signer);
        _registerInterface(bytes4(keccak256('MINT_WITH_ADDRESS')));
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

    /// @notice The function for token minting. It creates a new token.
    ///         Must contain the signature of the format: `sha3(tokenContract.address.toLowerCase() + tokenId)`.
    ///         Where `tokenContract.address` is the address of the contract and tokenId is the id in uint256 hex format.
    ///         0 as uint256 must look like this: `0000000000000000000000000000000000000000000000000000000000000000`.
    ///         The message **must not contain** the standard prefix.
    /// @param id - The id of a new token (`tokenId`).
    /// @param v - v parameter of the ECDSA signature.
    /// @param r - r parameter of the ECDSA signature.
    /// @param s - s parameter of the ECDSA signature.
    /// @param fees - An array of the secondary fees for this token.
    /// @param supply - The supply amount for the token.
    /// @param uri - The URI suffix for the token. The suffix with `tokenURIPrefix` usually complements ipfs link to metadata object.
    ///        The URI must link to JSON object with various fields: `name, description, image, external_url, attributes`.
    ///        Can also contain another various fields.
    function mint(uint256 id, uint8 v, bytes32 r, bytes32 s, Fee[] memory fees, uint256 supply, string memory uri) public {
        require(isSigner(ecrecover(keccak256(abi.encodePacked(this, id)), v, r, s)), "signer should sign tokenId");
        _mint(id, fees, supply, uri);
    }
}

/**
 * @title MultiUserToken
 * @dev Only owner can mint tokens.
 */
contract MultiUserToken is MultiToken {
    /// @notice Token minting event.
    event CreateERC1155_v1(address indexed creator, string name, string symbol);

    /// @notice The contract constructor.
    /// @param name - The value for the `name`.
    /// @param symbol - The value for the `symbol`.
    /// @param contractURI - The URI with contract metadata.
    ///        The metadata should be a JSON object with fields: `id, name, description, image, external_link`.
    ///        If the URI containts `{address}` template in its body, then the template must be substituted with the contract address.
    /// @param tokenURIPrefix - The URI prefix for all the tokens. Usually set to ipfs gateway.
    /// @param signer - The address of the initial signer.
    constructor(string memory name, string memory symbol, string memory contractURI, string memory tokenURIPrefix, address signer) MultiToken(name, symbol, signer, contractURI, tokenURIPrefix) public {
        emit CreateERC1155_v1(msg.sender, name, symbol);
    }

    /// @notice The function for token minting. It creates a new token. Can be called only by the contract owner.
    ///         Must contain the signature of the format: `sha3(tokenContract.address.toLowerCase() + tokenId)`.
    ///         Where `tokenContract.address` is the address of the contract and tokenId is the id in uint256 hex format.
    ///         0 as uint256 must look like this: `0000000000000000000000000000000000000000000000000000000000000000`.
    ///         The message **must not contain** the standard prefix.
    /// @param id - The id of a new token (`tokenId`).
    /// @param v - v parameter of the ECDSA signature.
    /// @param r - r parameter of the ECDSA signature.
    /// @param s - s parameter of the ECDSA signature.
    /// @param fees - An array of the secondary fees for this token.
    /// @param supply - The supply amount for the token.
    /// @param uri - The URI suffix for the token. The suffix with `tokenURIPrefix` usually complements ipfs link to metadata object.
    ///        The URI must link to JSON object with various fields: `name, description, image, external_url, attributes`.
    ///        Can also contain another various fields.
    function mint(uint256 id, uint8 v, bytes32 r, bytes32 s, Fee[] memory fees, uint256 supply, string memory uri) onlyOwner public {
        super.mint(id, v, r, s, fees, supply, uri);
    }
}