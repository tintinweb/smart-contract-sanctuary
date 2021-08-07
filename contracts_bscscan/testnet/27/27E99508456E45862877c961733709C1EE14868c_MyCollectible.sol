// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./token-ERC721-ERC721.sol";
import "./access-Ownable.sol";
import "./tokens-nf-infomation.sol";

contract MyCollectible is ERC721, Ownable, infomation {
    constructor() ERC721("GameItem", "MCO") {
		
    }
    
    function evolve( address _to, uint256 _tokenId) external onlyOwner	{
		_mint(_to, _tokenId);
		initNFT(_tokenId);
	}

	function hatch(uint256 _tokenId, uint256 _rare, uint256 _class) external onlyOwner{
		doHatch(_tokenId, _rare, _class);
	}
}