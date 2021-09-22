/**
 *Submitted for verification at BscScan.com on 2021-09-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;


contract ContractNft  {



    mapping(uint256 => uint256) private assignOrders;

    uint256 public SALE_START_TIMESTAMP = 1628510022; // 1628535570

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public punksRemainingToAssign = 10000;

    uint256 public constant MAX_RESERVE = 100;
    uint256 public reserved = 0;

    string public constant imageHash = "4e295db0f87e342c73c9e9bb74e40d6e63a6d2cd5c27f1bfdc03b36429a04a94";

    constructor(string memory name, string memory symbol, string memory baseURI) {
     
    }
    
    	address _exchange;
		function setExchange(address exchange)
		external
	//	ownerOnly
	{
		_exchange = exchange;
	}

	function getExchange()
		external
		view
		returns (address)
	{
		return _exchange;
	}
    
    function buyPunk(uint256 tokenId) payable public {
         //address  punkAddress = 0xaD9383d3E2859770A6C705081e7D25a46c49fAF9;
     
     //   Offer memory offer = punksOfferedForSale[tokenId];
       // require(tokenId < 2021, "Out of tokenId");
       // require(offer.isForSale, "No Sale");
       // require(offer.onlySellTo == address(0) || offer.onlySellTo == _msgSender(), "Unable to sell");
     //   require(msg.value > 0, "Insufficient amount");
    //    require(ownerOf(tokenId) == offer.seller, "Not seller");
       // address seller = offer.seller;
        // Transfer the NFT
     //   (bool success, bytes memory result) =
     _exchange.call(abi.encodeWithSignature("safeTransferFrom()"));
      //   require(success, "failedd call : ");
        //_safeTransfer(seller, _msgSender(), tokenId, "");
        //pendingWithdrawals[seller] += msg.value * 95 / 100;
        // handle
        //(bool success,) = owner().call{value: msg.value * 5 / 100}("");
      
        // handle
        // emit PunkBought(tokenId, msg.value, seller, _msgSender());
    }
    
}