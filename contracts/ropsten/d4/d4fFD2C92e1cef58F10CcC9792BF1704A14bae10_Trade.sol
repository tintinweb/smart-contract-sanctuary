/**
 *Submitted for verification at Etherscan.io on 2021-12-18
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.3;



// Part: ICollectible

interface ICollectible {
    function approve(address to, uint256 id) external;
    function safeTransferFrom(address from, address to, uint256 id) external;
    function ownerOf(uint256 id) external view returns (address);
    function getApproved(uint256 id) external view returns (address);
}

// File: TradeContract.sol

contract Trade {

    

    struct Offer {
        address trade_partner;
        address nft_address;
        uint256 nft_id;
        bool accepted;
    }

    mapping(address=>Offer) activeOffers;
    event OfferCreated(address,address);

    function createOffer(address _to, address _nft_address, uint256 _id) public {
        ICollectible nftContract;
        nftContract = ICollectible(_nft_address);
        require(nftContract.ownerOf(_id)==msg.sender,"you don't own that nft");
        require(nftContract.getApproved(_id)==address(this),'you must give this contract permission to trade that nft');

        Offer memory offer;
        offer = Offer(_to,_nft_address,_id,false);
        activeOffers[msg.sender] = offer;
        emit OfferCreated(msg.sender,_to);
    }

    function _executeSwap() internal {
        Offer memory sender = activeOffers[msg.sender];
        Offer memory receiver = activeOffers[sender.trade_partner];
        require(receiver.trade_partner == msg.sender, 'The other address has another active trade.');

        address nft1 = sender.nft_address;
        uint256 id1 = sender.nft_id;
        address nft2 = receiver.nft_address;
        uint256 id2 = receiver.nft_id;

        ICollectible nftContract1;
        ICollectible nftContract2;
        nftContract1 = ICollectible(nft1);
        nftContract2 = ICollectible(nft2);

        require(nftContract1.ownerOf(id1)==msg.sender,"You no longer own this");
        require(nftContract2.ownerOf(id2)==sender.trade_partner,"The other party no longer owns this");
        require(nftContract1.getApproved(id1)==address(this),'Contract not approved to make your trade');
        require(nftContract2.getApproved(id2)==address(this),'Contract not approved to make their trade');
        
        nftContract1.safeTransferFrom(msg.sender,sender.trade_partner,id1);
        nftContract2.safeTransferFrom(sender.trade_partner,msg.sender,id2);

    }

    function acceptOffer() external {
        Offer memory offer = activeOffers[msg.sender];
        address partner = offer.trade_partner;
        Offer memory offer2 = activeOffers[partner];
        require(offer2.trade_partner==msg.sender,'You have not been made an offer yet.');
        offer.accepted = true;
        activeOffers[msg.sender]= offer;
        if(offer2.accepted == true) {
            _executeSwap();
            _clearOffer(msg.sender);
            _clearOffer(offer.trade_partner);
        }
    }

    function getTradePartner(address account) external view returns (address) {
        Offer memory offer = activeOffers[account];
        return offer.trade_partner;
    }

    function getAddress(address account) external view returns (address) {
        Offer memory offer = activeOffers[account];
        return offer.nft_address;
    }

    function getOfferId(address account) external view returns (uint256) {
        Offer memory offer = activeOffers[account];
        return offer.nft_id;
    }

    function offerStatus(address account) external view returns (bool) {
        Offer memory offer = activeOffers[account];
        return offer.accepted;
    }

    function _clearOffer(address account) internal {
        delete activeOffers[account];
    }

    function clearOffer() external {
        _clearOffer(msg.sender);
    }
}