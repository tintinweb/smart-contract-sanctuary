// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./Ownable.sol";

contract Auction is Context, Ownable {

	IERC721 public nftAddress;
	
	uint256 sellingIds = 0;
	
	
	uint256[] private buytoken;
	
	struct SellingToken{
	    uint256 _tokenId;
	    uint256 _price;
	    address _tokenowner;
	    address _buyer;
	    bool    _exists;
	}
	
	mapping (uint256 => SellingToken)  public selltoken;
	mapping (uint256 => uint256) public tokenId_To_sellingId;

    event Buy (address indexed payer, uint tokenId, uint amount, uint time);
    event Sell(address indexed buyer, uint tokenId, uint price, uint time);


	function initialize(address _nftAddress) public onlyOwner virtual returns(bool){
		require(_nftAddress != address(0));
		nftAddress = IERC721(_nftAddress);
		return true;
	}
	
	function buy(uint256 _tokenId) public payable  {
        require(msg.value >= selltoken[tokenId_To_sellingId[_tokenId]]._price, "Your amount is less");
        require(selltoken[tokenId_To_sellingId[_tokenId]]._exists,"TokenId not exist");
        require(selltoken[tokenId_To_sellingId[_tokenId]]._buyer == address(0), "Token is already sold");
        nftAddress.safeTransferFrom(address(this), msg.sender, _tokenId);
        payable(address(this)).transfer(msg.value);
        selltoken[tokenId_To_sellingId[_tokenId]]._buyer = msg.sender;
        buytoken.push(_tokenId);
        delete selltoken[tokenId_To_sellingId[_tokenId]];
        emit Buy(msg.sender, _tokenId, msg.value, block.timestamp);
    }
    
	function sell(uint256 _tokenId, uint256 _price) public virtual {
	    require (msg.sender == nftAddress.ownerOf(_tokenId),"You are not owner");
	    require	(nftAddress.getApproved(_tokenId) == address(this), "Token not approved");
	    SellingToken memory sellToken;
    	sellToken = SellingToken({
    	   _tokenId : _tokenId,
    	   _price   : _price,
    	   _tokenowner : msg.sender,
    	   _buyer   : address(0),
    	   _exists  : true
    	});
    	sellingIds++;
	   	selltoken[sellingIds] = sellToken;
	   	tokenId_To_sellingId[_tokenId] = sellingIds;
        nftAddress.transferFrom(msg.sender, address(this), _tokenId);
	    emit Sell(msg.sender, _tokenId, _price, block.timestamp);
	}

    
}