/**
 *Submitted for verification at BscScan.com on 2021-12-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface INftSwap {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function tokenOfOwner(address owner) external view returns (uint256[] memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function getPropertiesByTokenIds(uint256[] calldata tokenIdArr ) external view returns(uint256[] memory);
    function getSellInfos(uint256[] calldata tokenIdArr) external view returns (uint256[] memory prices,uint256[] memory times);
}


library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(account)}
        return size > 0;
    }
}

contract MarketManage{
    using Address for address;

    string private _name = "ForthBox MarketManage";
    string private _symbol = "FBX MM";

    constructor() {
    }
    /* ========== VIEWS ========== */
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function totalSupply(address nftSwapAdress) public view returns (uint256) {
        require(nftSwapAdress.isContract(), "MarketManage: not Contract Adress");
        return INftSwap(nftSwapAdress).totalSupply();
    }

    function totalSupplys(address[] calldata nftSwaps) public view returns (uint256[] memory) {
        uint256 num = nftSwaps.length;
        uint256[] memory Token_list = new uint256[](uint256(num));
        for(uint256 i=0; i<=num; ++i) {
            Token_list[i] = INftSwap(nftSwaps[i]).totalSupply();
        }
        return Token_list;
    }
    function tokenByIndex(address nftSwapAdress,uint256 start, uint256 end) external view returns (uint256[] memory) {
        require(nftSwapAdress.isContract(), "MarketManage: not Contract Adress");
        INftSwap nftSwap = INftSwap(nftSwapAdress);
        require(end < nftSwap.totalSupply(), "ForthBoxNFT_Swap: global end out of bounds");

        uint256 num = end - start + 1;
        uint256[] memory Token_list = new uint256[](uint256(num));
        for(uint256 i=start; i<=end; ++i) {
            Token_list[i] =nftSwap.tokenByIndex(i);
        }
        return Token_list;
    }

    function tokenURI(address nftSwapAdress,uint256 tokenId) public view returns (string memory){      
        return INftSwap(nftSwapAdress).tokenURI(tokenId);
    }

    function getSellInfos(address nftSwapAdress,uint256[] calldata tokenIdArr) external view returns (uint256[] memory prices,uint256[] memory times) {
        require(nftSwapAdress.isContract(), "MarketManage: not Contract Adress");
        return INftSwap(nftSwapAdress).getSellInfos(tokenIdArr);
    }

    function getPropertiesByTokenIds(address nftSwapAdress,uint256[] calldata tokenIdArr) external view returns(uint256[] memory){
        require(nftSwapAdress.isContract(), "MarketManage: not Contract Adress");
        return INftSwap(nftSwapAdress).getPropertiesByTokenIds(tokenIdArr);
    }

    function balanceOf(address nftSwapAdress,address account) public view returns (uint256) {
        require(nftSwapAdress.isContract(), "MarketManage: not Contract Adress");
        return INftSwap(nftSwapAdress).balanceOf(account);
    }

    function balanceOfs(address[] calldata nftSwaps,address account) public view returns (uint256[] memory) {
        uint256 num = nftSwaps.length;
        uint256[] memory Token_list = new uint256[](uint256(num));
        for(uint256 i=0; i<=num; ++i) {
            Token_list[i] = INftSwap(nftSwaps[i]).balanceOf(account);
        }
        return Token_list;
    }

    function tokenOfOwner(address nftSwapAdress,address owner) public view returns (uint256[] memory) {
        require(nftSwapAdress.isContract(), "MarketManage: not Contract Adress");
        INftSwap nftSwap = INftSwap(nftSwapAdress);
        return nftSwap.tokenOfOwner(owner);
    }

}