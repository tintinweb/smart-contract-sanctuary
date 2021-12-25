pragma solidity ^0.8.0;

import './CollectibleMinimalInterface.sol';
import "./Ownable.sol";

contract Trade is Ownable {

    struct Offer {
        address trade_partner;
        address[] nft_address;
        uint256[] nft_id;
        bool accepted;
        uint256 nft_count;
        uint256 matic_offer;
        bool status;
    }

    mapping(address=>Offer) activeOffers;
    event OfferCreated(address sender,address receiver);
    event OfferClosed(address address1,address address2);
    event OfferCleared(address sender);
    event OfferAccepted(address address1, address address2);
    mapping(address=>uint256) royaltyEscrow;
    uint256 royalty = 50000000000000000; 
    address developer;
    uint256 public totalRoyalties;
    uint256 public availableRoyalties;
    bool private transferLocked;
    constructor() {
        developer = msg.sender;
    }


    function _chargeRoyalty() internal {
        require(msg.value >= royalty || royaltyEscrow[msg.sender]>=royalty, 'Must deposit developer fee.');
        royaltyEscrow[msg.sender] = royaltyEscrow[msg.sender] + royalty;
    }

    
    function offerStatus(address account) public view returns (bool) {
        Offer memory offer = activeOffers[account];
        return offer.status;
    }

    function collectRoyalty(uint256 amount) public onlyOwner {
        require(availableRoyalties>=amount);
       (bool success, ) = msg.sender.call{value:amount}("");
       require(success,'Transfer Failed');
        availableRoyalties = availableRoyalties - amount;
    }


    function createOffer(address _to, address[] memory _nft_address, uint256[] memory _id, uint256 matic) public payable {

        require(offerStatus(msg.sender)==false,'You have an active offer, please either decline or clear the offer.');
        require(_to != address(0),'Cannot send to zero address');
        _chargeRoyalty();
      
        require(msg.value >= matic + royalty,"You must send MATIC matching the value offered.");

        if(_nft_address.length!=0){
        for(uint i=0; i<_nft_address.length; i++) {
        ICollectible nftContract;
        nftContract = ICollectible(_nft_address[i]);
        require(nftContract.ownerOf(_id[i])==msg.sender,"You don't own all of the offered nfts.");
        require(nftContract.getApproved(_id[i])==address(this),'You must give this contract permission to trade all offered nfts.');
        }}

        uint256 nft_count = _nft_address.length;
        Offer memory offer;
        offer = Offer(_to,_nft_address,_id,false,nft_count,matic,true);
        activeOffers[msg.sender] = offer;
        emit OfferCreated(msg.sender,_to);
    }

    function _executeSwap() internal {

        require(!transferLocked,'Transfer is locked');
        transferLocked = true;
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
        
        
        (bool success, ) = sender.trade_partner.call{value:sender.matic_offer}("");
        (bool success2, ) = receiver.trade_partner.call{value:receiver.matic_offer}("");
        require(success,'Transfer Failed');
        require(success2, 'Transfer Failed');
        royaltyEscrow[msg.sender] = royaltyEscrow[msg.sender]-royalty;
        royaltyEscrow[sender.trade_partner] = royaltyEscrow[sender.trade_partner]-royalty;
        totalRoyalties = totalRoyalties + 2*royalty;
        availableRoyalties = availableRoyalties +2*royalty;
        transferLocked = false;
    }

    function acceptOffer() external {
        Offer memory offer = activeOffers[msg.sender];
        require(offer.status, "You have no active offers.");
        address partner = offer.trade_partner;
        Offer memory offer2 = activeOffers[partner];
        require(offer2.trade_partner==msg.sender,'You have not been connected to a matching offer yet.');
        

        offer.accepted = true;
        activeOffers[msg.sender] = offer;
        
        if(offer2.accepted == true) {
            _executeSwap();
            _clearOffer(msg.sender);
            _clearOffer(offer.trade_partner);
            emit OfferClosed(msg.sender, offer.trade_partner);
        }
        emit OfferAccepted(msg.sender, offer.trade_partner);
    }

    function clearOffer() external {
        require(!transferLocked,'Trade currently locked');

        transferLocked = true;
        Offer memory offer = activeOffers[msg.sender];
        Offer memory offer2 = activeOffers[offer.trade_partner];
        
        if (offer2.trade_partner == msg.sender){
            if (offer2.accepted) {
                offer2.accepted = false;
                activeOffers[offer.trade_partner] = offer2;
            }
        }

        if (offer.status) {
           (bool success, ) = msg.sender.call{value:offer.matic_offer}("");
            require(success,'Transfer failed');
        } 

        (bool success2, ) = msg.sender.call{value:royalty}("");
        royaltyEscrow[msg.sender] = royaltyEscrow[msg.sender]-royalty;
        _clearOffer(msg.sender);
         emit OfferCleared(msg.sender);
        transferLocked = false;
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

    function acceptanceStatus(address account) external view returns (bool) {
        Offer memory offer = activeOffers[account];
        return offer.accepted;
    }


    function _clearOffer(address account) internal {
        delete activeOffers[account];
       
    }


    function getOfferItemCount(address account) external view returns (uint256) {
        Offer memory offer = activeOffers[account];
        return offer.nft_count;
    }

    function getOfferValue(address account) external view returns (uint256) {
        Offer memory offer = activeOffers[account];
        return offer.matic_offer;
    }


}