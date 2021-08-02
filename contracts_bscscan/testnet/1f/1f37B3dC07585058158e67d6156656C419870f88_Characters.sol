// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.0;

import "./tokens-nf-token-metadata.sol";
import "./ownership-ownable.sol";
import "./tokens-nf-infomation.sol";

/**
 * @dev This is an example contract implementation of NFToken with metadata extension.
 */
contract Characters is NFTokenMetadata, Ownable, infomation
{
	/**
	 * @dev Contract constructor. Sets metadata extension `name` and `symbol`.
	 */
	constructor()
	{
		nftName = "Crypto Dragon NFT";
		nftSymbol = "Dragon";
	}

	/**
	 * @dev Mints a new NFT.
	 * @param _to The address that will own the minted NFT.
	 * @param _tokenId of the NFT to be minted by the msg.sender.
	 * @param _uri String representing RFC 3986 URI.
	 */
	function evolve( address _to, uint256 _tokenId, string calldata _uri) external onlyOwner	{
		super._mint(_to, _tokenId);
		super._setTokenUri(_tokenId, _uri);
		initNFT(_tokenId);
	}

	function hatch(uint256 _tokenId, uint256 _rare, uint256 _class) external onlyOwner{
		doHatch(_tokenId, _rare, _class);
	}
}