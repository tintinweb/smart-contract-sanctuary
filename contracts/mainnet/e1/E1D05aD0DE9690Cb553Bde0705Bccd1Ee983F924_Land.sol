// SPDX-License-Identifier: MIT
// Degen Farm: El Dorado. Collectible NFT game
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./ERC721URIStorage.sol";

contract Land is ERC721URIStorage {

    uint constant public MAP_HEIGHT = 50;
    uint constant public LAND_TYPE_COUNT = 5;
    enum LandType  { None, Clay, Chalky, Sandy, Loamy, Peaty }

    struct LandPiece {
        LandType atype; // uint8
        int32    x;
        int32    y;
    }

    mapping (uint256 => LandPiece) public lands;

    mapping(address => bool) public trusted_markets;
    event TrustedMarket(address indexed _market, bool _state);

    constructor(string memory name_,
        string memory symbol_) ERC721(name_, symbol_)  {
    }

    function mint(address to, uint256 tokenId, uint randomSeed) external onlyOwner {
        int32 x = (int32)(tokenId / MAP_HEIGHT);
        int32 y = (int32)(tokenId % MAP_HEIGHT);
        LandPiece memory land = LandPiece(_createLandType(x, y, randomSeed), x, y);
        lands[tokenId] = land;
        _mint(to, tokenId);
    }

    function _createLandType(int32 x, int32 y, uint randomSeed) internal returns (LandType) {
        uint256 chosen = randomSeed % LAND_TYPE_COUNT;
        return (LandType)(chosen + 1);
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }

    function setTrustedMarket(address _market, bool _state) external onlyOwner {
        trusted_markets[_market] = _state;
        emit TrustedMarket(_market, _state);
    }

    function getUsersTokens(address _owner) external view returns (uint256[] memory) {
        //https://docs.soliditylang.org/en/v0.7.4/types.html#allocating-memory-arrays
        //So first we need calc size of array to be returned
        uint256 n = balanceOf(_owner);

        uint256[] memory result = new uint256[](n);
        for (uint16 i=0; i < n; i++) {
            result[i]=tokenOfOwnerByIndex(_owner, i);
        }
        return result;
    }

    function baseURI() public view  override returns (string memory) {
        return 'http://degens.farm/meta/lands/';
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

}