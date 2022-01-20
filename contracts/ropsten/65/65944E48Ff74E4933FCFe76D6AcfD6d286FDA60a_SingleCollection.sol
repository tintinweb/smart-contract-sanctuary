// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./libs.sol";
import "./Roles.sol";
import "./ERC721.sol";

/**
 * @title MintableOwnableToken
 * @dev anyone can mint token.
 */
contract SingleCollection is Ownable, ERC721Base, SignerRole, MinterRole {
    using BytesLibrary for bytes32;
    using StringLibrary for string;
    /// @notice Token minting event.
    event CreateERC721_v4(address indexed creator, string name, string symbol);
    
    struct MintingBatch{
        address payable owner;
        uint256 tokenId;
        Fee[] fees;
        string tokenURI;
    }

    /// @notice The contract constructor.
    /// @param name - The value for the `name`.
    /// @param symbol - The value for the `symbol`.
    /// @param contractURI - The URI with contract metadata.
    ///        The metadata should be a JSON object with fields: `id, name, description, image, external_link`.
    ///        If the URI containts `{address}` template in its body, then the template must be substituted with the contract address.
    /// @param tokenURIPrefix - The URI prefix for all the tokens. Usually set to ipfs gateway.
    /// @param signer - The address of the initial signer.
    constructor (string memory name, string memory symbol, string memory contractURI, string memory tokenURIPrefix, address signer) ERC721Base(name, symbol, contractURI, tokenURIPrefix) {
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
    function mint(uint256 tokenId, uint8 v, bytes32 r, bytes32 s, Fee[] memory _fees, string memory tokenURI) public  {
        require(isSigner(prepareMessage(tokenId, this, tokenURI).recover(v, r, s)), "signer should sign tokenId");
        _mint(msg.sender, tokenId, _fees);
        _setTokenURI(tokenId, tokenURI);
    }
    
    function mintBatch(MintingBatch[] memory mintingBatch) public {
        require(isOwner() || isMinter(msg.sender), "Only for owner and minters minting");
        for (uint i = 0; i < mintingBatch.length; i++){
            address payable owner = mintingBatch[i].owner;
            uint256 tokenId = mintingBatch[i].tokenId;
            Fee[] memory fees = mintingBatch[i].fees;
            string memory tokenURI = mintingBatch[i].tokenURI;
            
            _mint(owner, tokenId, fees, tokenURI);
        }
    }
    
    function _mint(address payable to, uint256 tokenId, Fee[] memory fees, string memory tokenURI) private {
        super._mint(to, tokenId, fees);
        _setTokenURI(tokenId, tokenURI);
    }
    
    function prepareMessage(uint256 _id, SingleCollection _contAddr, string memory tokenURI) private pure returns (string memory) {
        return keccak256(abi.encode(_id, address(_contAddr), tokenURI)).toString();
    }

    /// @notice This function can be called by the contract owner and it adds an address as a new signer.
    ///         The signer will authorize token minting by signing token ids.
    /// @param account - The address of a new signer.
    function addSigner(address account) public override onlyOwner {
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
    
    function addMinter(address account) public onlyOwner {
        _addMinter(account);
    }
    
    function removeMinter(address account) public onlyOwner{
        _removeMinter(account);
    }
}

contract Help {
    using StringLibrary for string;
    using BytesLibrary for bytes32;

    function prepareMessage(uint256 _id, address _contAddr, string memory tokenURI) public pure returns (string memory) {
        return keccak256(abi.encode(_id, _contAddr, tokenURI)).toString();
    }
}