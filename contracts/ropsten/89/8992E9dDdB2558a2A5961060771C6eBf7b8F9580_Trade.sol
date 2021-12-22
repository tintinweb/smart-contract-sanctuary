/**
 *Submitted for verification at Etherscan.io on 2021-12-22
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.3;



// Part: ICollectible

interface ICollectible {

    function ownerOf(uint256 id) external returns (address);
    function getApproved(uint256 id) external returns (address);
    function safeTransferFrom(address from, address to,  uint256 id) external;
    

}

// Part: OpenZeppelin/[email protected]/Context

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// Part: OpenZeppelin/[email protected]/Ownable

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: TradeContract.sol

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
    mapping(address=>uint256) royaltyEscrow;
    uint256 royalty = 50000000000000000; 
    address developer;
    uint256 public totalRoyalties;
    uint256 public availableRoyalties;

    constructor() {
        developer = msg.sender;
    }


    function _chargeRoyalty() internal {
        require(msg.value >= royalty || royaltyEscrow[msg.sender]>=royalty, 'Must deposit developer fee.');
        royaltyEscrow[msg.sender] = royaltyEscrow[msg.sender] + msg.value;
    }

    
    function offerStatus(address account) public view returns (bool) {
        Offer memory offer = activeOffers[account];
        return offer.status;
    }

    function collectRoyalty(uint256 amount) public onlyOwner {
        payable(msg.sender).transfer(amount);
        availableRoyalties = availableRoyalties - royalty;
    }

    function createOffer(address _to, address[] memory _nft_address, uint256[] memory _id, uint256 matic) public payable {
        require(offerStatus(msg.sender)==false,'You have an active offer, please either decline or clear the offer.');
        require(_to != address(0),'Cannot send to zero address');
        _chargeRoyalty();
        require(msg.sender.balance >= matic, "You don't have enough matic to make this trade offer.");
        for(uint i=0; i<_nft_address.length; i++) {
        ICollectible nftContract;
        nftContract = ICollectible(_nft_address[i]);
        require(nftContract.ownerOf(_id[i])==msg.sender,"You don't own all of the offered nfts.");
        require(nftContract.getApproved(_id[i])==address(this),'You must give this contract permission to trade all offered nfts.');
        }
        uint256 nft_count = _nft_address.length;
        Offer memory offer;
        offer = Offer(_to,_nft_address,_id,false,nft_count,matic,true);
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
        payable(sender.trade_partner).transfer(sender.matic_offer);
        payable(receiver.trade_partner).transfer(receiver.matic_offer);
        royaltyEscrow[msg.sender] = royaltyEscrow[msg.sender]-royalty;
        royaltyEscrow[sender.trade_partner] = royaltyEscrow[sender.trade_partner]-royalty;
        totalRoyalties = totalRoyalties + 2*royalty;
        availableRoyalties = availableRoyalties +2*royalty;
    }

    function acceptOffer() external payable {
        Offer memory offer = activeOffers[msg.sender];
        require(offer.status, "You have no active offers.");
        address partner = offer.trade_partner;
        Offer memory offer2 = activeOffers[partner];
        require(offer2.trade_partner==msg.sender,'You have not been connected to a matching offer yet.');
        require(msg.sender.balance>=offer.matic_offer,"You don't have enough MATIC to complete your offer.");
        require(msg.value>= offer.matic_offer,"You must send MATIC matching the value offered.");

        offer.accepted = true;
        activeOffers[msg.sender] = offer;
        if(offer2.accepted == true) {
            _executeSwap();
            _clearOffer(msg.sender);
            _clearOffer(offer.trade_partner);
            emit OfferClosed(msg.sender, offer.trade_partner);
        }
    }

    function clearOffer() external {
        Offer memory offer = activeOffers[msg.sender];
        Offer memory offer2 = activeOffers[offer.trade_partner];
        
        if (offer2.trade_partner == msg.sender){
            if (offer2.accepted) {
                offer2.accepted = false;
                payable(offer.trade_partner).transfer(offer2.matic_offer);
                activeOffers[offer.trade_partner] = offer2;
            }
        }

        if (offer.accepted) {
            payable(msg.sender).transfer(offer.matic_offer);
        }
         
        payable(msg.sender).transfer(royalty);
        royaltyEscrow[msg.sender] = royaltyEscrow[msg.sender]-royalty;
        _clearOffer(msg.sender);

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