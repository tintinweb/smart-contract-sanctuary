pragma solidity ^0.5.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Metadata.sol";
import "./MinterRole.sol";
import "./Ownable.sol";

/**
 * @title Full ERC721 Token
 * This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract SomniumSpace is ERC721, ERC721Enumerable, ERC721Metadata, MinterRole, Ownable {
    constructor (string memory name, string memory symbol) public ERC721Metadata(name, symbol) Ownable() {
        // solhint-disable-previous-line no-empty-blocks
    }
    
    /**
     * @dev Function to mint tokens.
     * @param to The address that will receive the minted tokens.
     * @param tokenId The token id to mint.
     * @param tokenURI The token URI of the minted token.
     * @return A boolean that indicates if the operation was successful.
     */
    function mintWithTokenURI(address to, uint256 tokenId, string memory tokenURI, string memory tokenURLSomnium) public onlyMinter returns (bool) {
        _mint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
        _setTokenURLSomnium(tokenId, tokenURLSomnium);
        return true;
    }
}