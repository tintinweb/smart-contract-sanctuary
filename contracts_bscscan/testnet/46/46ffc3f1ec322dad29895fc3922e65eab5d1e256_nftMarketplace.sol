pragma solidity 0.8.7;

import "./NFT_Contract_mempoolbots.sol";

//SPDX-License-Identifier: UNLICENSED

/// @title Escrow contract
contract nftMarketplace is IERC721Receiver {
 
    struct Sale {
        uint256 nftId;
        uint256 price;
        address owner;
    }
    
    struct Offer {
        uint256 offer;
        address giver;
    }
    
    Offer[] public offers;
    
    uint256 offersLen = 0;
    
    BIG public token;

    Sale[] public sales;

    mapping(uint256 => uint256) public nftToSale;
    
    mapping(uint256 => uint256) public nftOffer;

    event NewSale(uint256 indexed nftId, uint256 price, uint256 saleId);
    
    event Sold(uint256 indexed nftId, uint256 price, address indexed oldOwner, address indexed newOwner);

    /// @notice Constructor
    /// @param _token nft token address
    constructor(address _token)  {
        token = BIG(_token);
        Offer memory o = Offer({offer: 0 , giver: address(0)});
        offers.push(o);
        Sale memory sa = Sale({nftId: 0, price: 0 , owner: address(0)});
        sales.push(sa);
    }

    function offer(uint256 _nftId) public payable{
        if(nftOffer[_nftId] != 0){
            require(msg.value > offers[nftOffer[_nftId]].offer , "new offer cant be less than current");
            bool succes = payable(offers[nftOffer[_nftId]].giver).send(offers[nftOffer[_nftId]].offer);
            if(!succes){
                revert();
            }
            offers[nftOffer[_nftId]].offer = msg.value;
            offers[nftOffer[_nftId]].giver = msg.sender;
        }else if(nftOffer[_nftId] == 0){
            Offer memory o = Offer({offer: msg.value , giver: msg.sender});
            offers.push(o);
            nftOffer[_nftId] =  offers.length - 1;
        }
        
    }
    
    function acceptOffer(uint256 _nftId) public {
        require(msg.sender == token.ownerOf(_nftId), "This isnt your nft to accept");
        require(nftOffer[_nftId] != 0, "Your nft does not have an offer");
        require(offers[nftOffer[_nftId]].giver != address(0), "This would burn the NFT");
        token.safeTransferFrom(msg.sender ,offers[nftOffer[_nftId]].giver, _nftId);
        bool succes = payable(msg.sender).send(offers[nftOffer[_nftId]].offer);
        if(!succes){
                revert();
        }
        nftOffer[_nftId] = 0;
        
    }
    
    function cancelOffer(uint256 _nftId) public {
        require(msg.sender == offers[nftOffer[_nftId]].giver, "you must have been the offer giver");
        bool succes = payable(msg.sender).send(offers[nftOffer[_nftId]].offer);
        if(!succes){
                revert();
        }
        nftOffer[_nftId] = 0;
    }

    function showOffer(uint256 _nftId) view public returns (Offer memory){
        Offer memory o = offers[nftOffer[_nftId]];
        return o;
    }
    
    function showSale(uint256 _nftId) view public returns (Sale memory){
        Sale memory s = sales[nftToSale[_nftId]];
        return s;
    }


    // /// @notice Buy token
    // /// @param _saleId Index of sales[]
    function buy(uint256 _nftId) public payable {
        require(nftToSale[_nftId] != 0);
        Sale memory s = sales[nftToSale[_nftId]];

        // TODO: uncomment this to avoid the owner buying his own tokens
        // require(s.owner != msg.sender);
        require(msg.value >= s.price);
        
        uint256 refund = msg.value - s.price;
        if(refund > 0){
            payable(msg.sender).transfer(refund);
        }
        payable(s.owner).transfer(s.price);

        // Transfer the token
        token.approve(msg.sender, s.nftId);
        token.safeTransferFrom(address(this), msg.sender, s.nftId);

        // Delete sale
        nftToSale[_nftId] = 0;
        delete sales[nftToSale[_nftId]];
        
    }

    
    function forSale(uint256 _nftId, uint256 _price) public{
        // You can only sell your own nft
        require(token.ownerOf(_nftId) == msg.sender);

        token.safeTransferFrom(msg.sender, address(this), _nftId);

        Sale memory s = Sale({
            nftId: _nftId,
            price: _price,
            owner: msg.sender
        });

        sales.push(s);

        uint256 saleId = sales.length - 1;

        nftToSale[_nftId] = saleId;
        
        emit NewSale(_nftId, _price, saleId);
    }


    function withdraw(uint256 _nftId) public{
        require(sales[nftToSale[_nftId]].owner == msg.sender);

        delete sales[nftToSale[_nftId]];
        delete nftToSale[_nftId];

        token.safeTransferFrom(address(this), msg.sender, _nftId);
    }
    
    function onERC721Received (
        address, 
        address, 
        uint256, 
        bytes calldata
    )override external returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    } 

    /// @notice nfts for sale quantity
    function nSale() public view returns(uint256) {
        return sales.length;
    }


}