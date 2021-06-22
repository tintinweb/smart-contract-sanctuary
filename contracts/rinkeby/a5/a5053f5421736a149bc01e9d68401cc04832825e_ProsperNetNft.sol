/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

pragma experimental ABIEncoderV2;

contract ProsperNetNft {
    
    enum nftSaleStatusType
    {
        forSale, notForSale
    }
    
    struct Nft{
        string id; //ipfs id
        uint price; //wei
        address payable artist;
        address previousOwner;
        address payable owner;
        nftSaleStatusType status;
    }
    
    event NftCreated(
        string id, //ipfs id
        uint price, //wei
        address artist,
        address previousOwner,
        address owner,
        nftSaleStatusType status
    );
    
    event PriceChanged(
        string id, //ipfs id
        uint price, //wei
        address owner
    );
    
    event SaleStatusChanged(
        string id, //ipfs id
        address owner,
        nftSaleStatusType status
    );

    event NftPurchased(
        string id, //ipfs id
        uint ownerCredit, //wei
        uint artistCredit,
        address artist,
        address previousOwner,
        address owner,
        nftSaleStatusType status
    );

    // mapping(string => Nft) nftCollection; //Nft.id -> Nft object
    Nft[] public nftCollection;
    uint public nftCount = 0;
    Nft public nftDummyCollection;
    uint constant public ROYALTY_RATIO = 1000; //scale: 1% = 100 ROYALTY_RATION

    function nftDoExist(string memory _id) public view returns (bool)
    {
        for (uint index = 0; index < nftCollection.length; index++) {
            if( keccak256(bytes(nftCollection[index].id)) == keccak256(bytes(_id)) ){
                return true;
            }
        }
        return false;
    }

    function getNft(string memory _id) private view returns (Nft memory)
    {
        for (uint index = 0; index < nftCollection.length; index++) {
            if( keccak256(bytes(nftCollection[index].id)) == keccak256(bytes(_id)) ){
                return nftCollection[index];
            }
        }
        return Nft("",0, payable(address (0x0)), address(0), payable(address(0)), nftSaleStatusType.notForSale);
    }

    function updateNft(string memory _id, Nft memory updatedNft) private returns (bool)
    {
        for (uint index = 0; index < nftCollection.length; index++) {
            if( keccak256(bytes(nftCollection[index].id)) == keccak256(bytes(_id)) ){
                nftCollection[index] = updatedNft;
                return true;
            }
        }
        return false;
    }

    function createNft(string memory _id, uint _price) public
    {
        require( nftDoExist(_id) == false, "NFT already exists" );
        nftSaleStatusType status = nftSaleStatusType.notForSale;
        // nftCollection[_id] = Nft(_id, _price, msg.sender, msg.sender, msg.sender, status);
        nftCollection.push( Nft(_id, _price, payable(msg.sender), msg.sender, payable(msg.sender), status) );
        // nftDummyCollection = nftCollection[_id];
        nftCount++;
        emit NftCreated(_id, _price, msg.sender,msg.sender, msg.sender, status);
    }
    
    function changePrice(string memory _id, uint newPrice) public
    {
        // nftCollection[_id].price = newPrice;
        Nft memory nft = getNft(_id);
        nft.price = newPrice;

        require( updateNft(_id, nft), "no nft object found");
        emit PriceChanged(_id, newPrice, msg.sender);
    }
    
    function openToSale(string memory _id) public
    {
        // nftCollection[_id].status = nftSaleStatusType.forSale;
        Nft memory nft = getNft(_id);

        require( nft.status != nftSaleStatusType.forSale , "status is already as per requirements");
        nft.status = nftSaleStatusType.forSale;

        require( updateNft(_id, nft), "no nft object found");

        emit SaleStatusChanged(_id, msg.sender, nftSaleStatusType.forSale);
    }
    
    function notForSale(string memory _id) public 
    {
        // nftCollection[_id].status = nftSaleStatusType.forSale;
        Nft memory nft = getNft(_id);

        require( nft.status != nftSaleStatusType.notForSale , "status is already as per requirements");
        nft.status = nftSaleStatusType.notForSale;

        require( updateNft(_id, nft), "no nft object found");

        emit SaleStatusChanged(_id, msg.sender, nftSaleStatusType.forSale);
    }

    //=========Transactions==============

    function purchaseNft(string memory _id) public payable {

        Nft memory _nft = getNft(_id);

        require(msg.value >= _nft.price, "Not enough credits");

        require(_nft.status == nftSaleStatusType.forSale);

        uint artistCredit = (msg.value * ROYALTY_RATIO )/10000;
        uint ownerCredit = msg.value - artistCredit;
        payable(address(_nft.owner)).transfer(ownerCredit);
        payable(address(_nft.artist)).transfer(artistCredit);

        _nft.previousOwner = _nft.owner;
        _nft.owner = payable(msg.sender);
        _nft.status = nftSaleStatusType.notForSale;

        updateNft(_id, _nft);
        emit NftPurchased(_id, ownerCredit, artistCredit, _nft.artist, _nft.previousOwner, _nft.owner, _nft.status);
    }
}