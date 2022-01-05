// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.7.6;

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
}

interface IERC721Enumerable is IERC721 {
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}

interface INonFungiblePositionManager is IERC721Enumerable {
       function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
}

contract UniswapPosition {

    address public nonfungiblePositionManager;
        
    constructor(address _nonfungiblePositionManager) {
       nonfungiblePositionManager = _nonfungiblePositionManager;
    }
    
    function _balanceOf(address _address) internal view returns (uint256 balance) {
        return  INonFungiblePositionManager(nonfungiblePositionManager).balanceOf(_address);
    }

    function _positions(address _address, uint256 _index) internal view returns (uint256 _tokenId, address _token0, address _token1) {
        uint256 tokenId = INonFungiblePositionManager(nonfungiblePositionManager).tokenOfOwnerByIndex(_address, _index);
        (,, address token0, address token1,,,,,,,,) = INonFungiblePositionManager(nonfungiblePositionManager).positions(tokenId);
        return (tokenId, token0, token1);
    }

    function getTokenIds(address _address) public view returns(uint256[] memory _tokenIds, address[] memory _tokens0, address[] memory _tokens1) {
        uint256 balance = _balanceOf(_address);
        uint256[] memory tokenIds =  new uint256[](balance);
        address[] memory tokens0 = new address[](balance);
        address[] memory tokens1 = new address[](balance);
        for(uint256 i = 0; i < balance; i++) {
            (uint256 tokenId, address token0, address token1) = _positions(_address, i);
            tokenIds[i] = tokenId;
            tokens0[i] = token0;
            tokens1[i] = token1;
        }
        return (tokenIds, tokens0, tokens1);
    }
}