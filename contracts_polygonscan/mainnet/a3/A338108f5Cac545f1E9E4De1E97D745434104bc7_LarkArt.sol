// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./ERC721URIStorage.sol";

contract LarkArt is ERC721URIStorage, Ownable {
    uint256 public id;
    IERC20 public immutable LARK;
    uint256 public fee = 50 * 1e18;
    address public feeTo;

    constructor(IERC20 _lark, address _feeTo) ERC721("LarkArtGallery", "LAG"){
        id = 0;
        LARK = _lark;
        feeTo = _feeTo;
    }

    function createArtNFT (string memory _tokenURI) external returns (uint256){
        LARK.transferFrom(msg.sender, feeTo, fee);

        uint256 tokenId = id;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, _tokenURI);

        id ++;

        return tokenId;
    }

    //get Owners by id and limit
    function getOwnersbyLimit(uint256 _id, uint256 _limit) external view returns(address[] memory ownerData){
        uint256 length = _id > _limit ? _limit : (_id + 1);
        ownerData = new address[](length);

        for(uint256 i = 0; i < length; i ++){
            ownerData[i] = ownerOf(_id + i + 1 - length);
        }
        return ownerData;
    }

    //get tokenURIs by id and limit
    function getURIbyLimit(uint256 _id, uint256 _limit) external view returns (string[] memory uRIData){
        uint256 length = _id > _limit ? _limit : (_id + 1);
        uRIData = new string[](length);

         for(uint256 i = 0; i < length; i ++){
            uRIData[i] = tokenURI(_id  + i + 1 - length);
        }
        return uRIData;
    }

    function getAllOwner() external view returns(address[] memory allOwner){
        allOwner = new address[](id);
        
        for(uint256 i = 0; i < id; i ++){
            allOwner[i] = ownerOf(i);
        }
        return allOwner;
    }

    function getAllURI() external view returns(string[] memory allURI){
        allURI = new string[](id);
        
        for(uint256 i = 0; i < id; i ++){
            allURI[i] = tokenURI(i);
        }
        return allURI;
    }

    //set fee and feeTo by owner
    function setFee(uint256 _fee, address _feeTo) external onlyOwner {
        fee = _fee;
        feeTo = _feeTo;
    }

}