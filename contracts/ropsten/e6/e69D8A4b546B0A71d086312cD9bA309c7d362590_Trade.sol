/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.9;



// Part: ICollectible

interface ICollectible {

    function ownerOf(uint256 id) external returns (address);
    function getApproved(uint256 id) external returns (address);
    function safeTransferFrom(address from, address to,  uint256 id) external;
    

}

// File: TradeContract.sol

contract Trade {

    struct Offer {
        address trade_partner;
        address[] nft_address;
        uint256[] nft_id;
        bool accepted;
        uint256 count;
    }

    mapping(address=>Offer) activeOffers;
    event OfferCreated(address,address);
    mapping(address=>uint256) royaltyEscrow;
    uint256 royalty = 10000000000000000; 
    address developer;

    constructor() {
        developer = msg.sender;
    }

    function _chargeRoyalty() internal {
        require(msg.value >= royalty || royaltyEscrow[msg.sender]>=royalty, 'Must deposit transaction fee.');
        royaltyEscrow[msg.sender] = royaltyEscrow[msg.sender] + msg.value;
    }
    

    function createOffer(address _to, address[] memory _nft_address, uint256[] memory _id) public payable {
        _chargeRoyalty();
        for(uint i=0; i<_nft_address.length; i++) {
        ICollectible nftContract;
        nftContract = ICollectible(_nft_address[i]);
        require(nftContract.ownerOf(_id[i])==msg.sender,"you don't own that nft");
        require(nftContract.getApproved(_id[i])==address(this),'you must give this contract permission to trade that nft');
        }
        uint256 count = _nft_address.length;
        Offer memory offer;
        offer = Offer(_to,_nft_address,_id,false,count);
        activeOffers[msg.sender] = offer;
        emit OfferCreated(msg.sender,_to);
    }

    function _executeSwap() internal {
        Offer memory sender = activeOffers[msg.sender];
        Offer memory receiver = activeOffers[sender.trade_partner];
        require(receiver.trade_partner == msg.sender, 'The other address has another active trade.');

        for(uint i=0; i< sender.nft_address.length; i++){
            address nft = sender.nft_address[i];
            uint256 id = sender.nft_id[i];
            ICollectible nftContract;
            nftContract = ICollectible(nft);
            require(nftContract.ownerOf(id)==msg.sender,"You no longer own this");
            require(nftContract.getApproved(id)==address(this),'Contract not approved to make your trade');
            nftContract.safeTransferFrom(msg.sender,sender.trade_partner,id); 
        }

        for(uint i=0; i< receiver.nft_address.length; i++){
            address nft = receiver.nft_address[i];
            uint256 id = receiver.nft_id[i];
            ICollectible nftContract;
            nftContract = ICollectible(nft);
            require(nftContract.ownerOf(id)==sender.trade_partner,"Trade partnet no longer owns NFT");
            require(nftContract.getApproved(id)==address(this),'Contract not approved to make your trade');
            nftContract.safeTransferFrom(sender.trade_partner,msg.sender,id); 
        }
        payable(developer).transfer(2*royalty);
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

    function getAddress(address account,uint i) external view returns (address) {
        Offer memory offer = activeOffers[account];
        return offer.nft_address[i];
    }

    function getOfferId(address account,uint i) external view returns (uint256) {
        Offer memory offer = activeOffers[account];
        return offer.nft_id[i];
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
         payable(msg.sender).transfer(royalty);
        royaltyEscrow[msg.sender] = royaltyEscrow[msg.sender]-royalty;
    }

    function getOfferItemCount(address account) external view returns (uint256) {
        Offer memory offer = activeOffers[account];
        return offer.count;
    }


}