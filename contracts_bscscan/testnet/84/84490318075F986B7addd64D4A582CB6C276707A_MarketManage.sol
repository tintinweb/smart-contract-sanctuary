/**
 *Submitted for verification at BscScan.com on 2021-12-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IERC721 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function tokenOfOwner(address owner) external view returns (uint256[] memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function getPropertiesByTokenIds(uint256[] calldata tokenIdArr ) external view returns(uint256[] memory);
    function bExistsID(uint256 tokenId) external view returns (bool);
    function getSellInfos(uint256[] calldata tokenIdArr) external view returns ( address[] memory addrs,uint256[] memory prices,uint256[] memory times);
    function ownerOf(uint256 tokenId) external view returns (address);
}
interface INftSwap is IERC721 {
    function getSellInfos(uint256[] calldata tokenIdArr) external view returns ( address[] memory addrs,uint256[] memory prices,uint256[] memory times);
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

    string public name = "ForthBox MarketManage";
    string public symbol = "FBX MM";

    constructor() {
    }

    /* ========== common total ========== */
    function totalSupply(address nftAdress) public view returns (uint256) {
        require(nftAdress.isContract(), "MarketManage: not Contract Adress");
        return IERC721(nftAdress).totalSupply();
    }

    function totalSupplys(address[] calldata nftAdressArr) public view returns (uint256[] memory) {
        uint256 num = nftAdressArr.length;
        uint256[] memory Token_list = new uint256[](uint256(num));
        for(uint256 i=0; i<num; ++i) {
            Token_list[i] = IERC721(nftAdressArr[i]).totalSupply();
        }
        return Token_list;
    }

    function tokenByIndex(address nftAdress,uint256 start, uint256 end) external view returns (uint256[] memory) {
        require(nftAdress.isContract(), "MarketManage: not Contract Adress");
        INftSwap nftSwap = INftSwap(nftAdress);
        require(end < nftSwap.totalSupply(), "ForthBoxNFT_Swap: global end out of bounds");

        uint256 num = end - start + 1;
        uint256[] memory Token_list = new uint256[](uint256(num));
        for(uint256 i=start; i<=end; ++i) {
            Token_list[i] =nftSwap.tokenByIndex(i);
        }
        return Token_list;
    }

    function tokenURI(address nftAdress,uint256 tokenId) public view returns (string memory){      
        return IERC721(nftAdress).tokenURI(tokenId);
    }

    function getPropertiesByTokenIds(address nftAdress,uint256[] calldata tokenIdArr) external view returns(uint256[] memory){
        require(nftAdress.isContract(), "MarketManage: not Contract Adress");
        return IERC721(nftAdress).getPropertiesByTokenIds(tokenIdArr);
    }

    /* ========== common account ========== */
    function balanceOf(address nftAdress,address account) public view returns (uint256) {
        require(nftAdress.isContract(), "MarketManage: not Contract Adress");
        return IERC721(nftAdress).balanceOf(account);
    }

    function balanceOfs(address[] calldata nftAdressArr,address account) public view returns (uint256[] memory) {
        uint256 num = nftAdressArr.length;
        uint256[] memory Token_list = new uint256[](uint256(num));
        for(uint256 i=0; i<num; ++i) {
            Token_list[i] = IERC721(nftAdressArr[i]).balanceOf(account);
        }
        return Token_list;
    }

    function tokenOfOwner(address nftAdress,address owner) public view returns (uint256[] memory) {
        require(nftAdress.isContract(), "MarketManage: not Contract Adress");
        return IERC721(nftAdress).tokenOfOwner(owner);
    }

    function bExistsID(address nftAdress,uint256 tokenId) public view returns (bool) {
        require(nftAdress.isContract(), "MarketManage: not Contract Adress");
        return IERC721(nftAdress).bExistsID(tokenId);
    }

    function ownerOf(address nftAdress,uint256 tokenId) public view returns (address) {
        require(nftAdress.isContract(), "MarketManage: not Contract Adress");
        return IERC721(nftAdress).ownerOf(tokenId);
    }

    /* ========== only swsap ========== */
    function getSellInfos(address nftSwapAdress,uint256[] calldata tokenIdArr) external view returns (address[] memory addrs,uint256[] memory prices,uint256[] memory times) {
        require(nftSwapAdress.isContract(), "MarketManage: not Contract Adress");
        return INftSwap(nftSwapAdress).getSellInfos(tokenIdArr);
    }
}