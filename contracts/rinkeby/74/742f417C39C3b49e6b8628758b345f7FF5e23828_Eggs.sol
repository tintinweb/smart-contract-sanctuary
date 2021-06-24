// SPDX-License-Identifier: MIT
// Degen'$ Farm: Collectible NFT game (https://degens.farm)
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./ERC721URIStorage.sol";

contract Eggs is ERC721URIStorage {

    mapping(address => bool) public trusted_markets;
    event TrustedMarket(address indexed _market, bool _state);

    constructor() ERC721("Degen$ Farm Eggs", "EGG")  {
    }

    function mint(
        address to, 
        uint256 tokenId
        ) external onlyOwner {
    	
        _mint(to, tokenId);
    }
    
    function setTrustedMarket(address _market, bool _state) external onlyOwner {
        trusted_markets[_market] = _state;
        emit TrustedMarket(_market, _state);
    }

    function getUsersTokens(address _owner) external view returns (uint256[] memory) {
        //We can return only uint256[] memory, but we cant use push 
        // with memory arrays. 
        //https://docs.soliditylang.org/en/v0.7.4/types.html#allocating-memory-arrays
        uint256 n = balanceOf(_owner); 

        uint256[] memory result = new uint256[](n);
        for (uint16 i=0; i < n; i++) {
            result[i]=tokenOfOwnerByIndex(_owner, i);
        }
        return result;
    }

    function baseURI() public view  override returns (string memory) {
        return 'http://degens.farm/meta/eggs/';
    }
    
    /**
     * @dev Overriding standard function for gas safe traiding with trusted parts like DegenFarm
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `caller` must be added to trustedMarkets.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override {
        if (trusted_markets[msg.sender]) {
            _transfer(from, to, tokenId);
        } else {
            super.transferFrom(from, to, tokenId);
        }
    }

    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }
}