pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;


interface IKawaiiAirdropNFT {
    function claimNFT1155(address nftRegister, uint256 tokenId, address sender, uint8 v, bytes32 r, bytes32 s) external;
}

interface IKawaiiAirdopPackNFT {
    function claimPacked(address nftRegister, address sender, uint8 v, bytes32 r, bytes32 s) external;
}

interface IKawaiiCrafting {
    function craftingItem(bytes memory data) external;
}

interface IKawaiiDelivery {
    function delivery(address _nft1155Address, uint256[] memory _tokenIds, uint256[] memory _rateItems, uint256[] memory _amounts, uint256 timestamp, address sender, bytes memory adminSignedData, uint8 v, bytes32 r, bytes32 s) external;
}

interface IKawaiiSale {
    function buy(uint256 id, uint256 amount, address sender, uint8 v, bytes32 r, bytes32 s) external;
}

interface IKawaiiWarehouse {
    function upMaxCategoryOfUserPermit(address sender, string[] memory category, uint256[] memory amount, uint256 amountPayment, uint256 timestamp, bytes memory adminSignedData, uint8 v, bytes32 r, bytes32 s) external;
}

interface IKawaiiMinting {
    function convertItem(address _nft1155Address, uint256 _tokenId, uint256 _amount, uint256 _timestamp, address _sender, bytes memory _adminSignedData, uint8 v, bytes32 r, bytes32 s) external;
}

interface IKawaiiMarketplace {
    function createAuction(address _nftAddress, uint256 _tokenId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration, address sender, uint8 v, bytes32 r, bytes32 s) external;

    function bid(address _nftAddress, uint256 _tokenId, uint256 _tokenIndex, uint256 _amount, address sender, uint8 v, bytes32 r, bytes32 s) external;

    function cancelAuction(address _nftAddress, uint256 _tokenId, uint256 _tokenIndex, address sender, uint8 v, bytes32 r, bytes32 s) external;
}


contract KawaiiRelay {

    function createAuction(IKawaiiMarketplace _marketplace, address _nftAddress, uint256 _tokenId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration, address sender, uint8 v, bytes32 r, bytes32 s) external {
        _marketplace.createAuction(_nftAddress, _tokenId, _startingPrice, _endingPrice, _duration, sender, v, r, s);
    }

    function bid(IKawaiiMarketplace _marketplace, address _nftAddress, uint256 _tokenId, uint256 _tokenIndex, uint256 _amount, address sender, uint8 v, bytes32 r, bytes32 s) external {
        _marketplace.bid(_nftAddress, _tokenId, _tokenIndex, _amount, sender, v, r, s);
    }

    function cancelAuction(IKawaiiMarketplace _marketplace, address _nftAddress, uint256 _tokenId, uint256 _tokenIndex, address sender, uint8 v, bytes32 r, bytes32 s) external {
        _marketplace.cancelAuction(_nftAddress, _tokenId, _tokenIndex, sender, v, r, s);
    }


    function claimNFT1155(IKawaiiAirdropNFT kawaiiAirdropNFT, address nftRegister, uint256 tokenId, address sender, uint8 v, bytes32 r, bytes32 s) external {
        kawaiiAirdropNFT.claimNFT1155(nftRegister, tokenId, sender, v, r, s);
    }

    function claimPacked(IKawaiiAirdopPackNFT kawaiiAirdopPackNFT, address nftRegister, address sender, uint8 v, bytes32 r, bytes32 s) external {
        kawaiiAirdopPackNFT.claimPacked(nftRegister, sender, v, r, s);
    }

    function craftingItem(IKawaiiCrafting kawaiiCrafting, bytes memory data) external {
        kawaiiCrafting.craftingItem(data);
    }

    function delivery(IKawaiiDelivery kawaiiDelivery, address _nft1155Address, uint256[] memory _tokenIds, uint256[] memory _rateItems, uint256[] memory _amounts, uint256 timestamp, address sender, bytes memory adminSignedData, uint8 v, bytes32 r, bytes32 s) external {
        kawaiiDelivery.delivery(_nft1155Address, _tokenIds, _rateItems, _amounts, timestamp, sender, adminSignedData, v, r, s);
    }

    function buy(IKawaiiSale kawaiiSale, uint256 id, uint256 amount, address sender, uint8 v, bytes32 r, bytes32 s) external {
        kawaiiSale.buy(id, amount, sender, v, r, s);
    }

    function upMaxCategoryOfUserPermit(IKawaiiWarehouse kawaiiWarehouse, address sender, string[] memory category, uint256[] memory amount, uint256 amountPayment, uint256 timestamp, bytes memory adminSignedData, uint8 v, bytes32 r, bytes32 s) external {
        kawaiiWarehouse.upMaxCategoryOfUserPermit(sender, category, amount, amountPayment, timestamp, adminSignedData, v, r, s);
    }

    function convertItem(IKawaiiMinting kawaiiMinting, address _nft1155Address, uint256 _tokenId, uint256 _amount, uint256 _timestamp, address _sender, bytes memory _adminSignedData, uint8 v, bytes32 r, bytes32 s) external {
        kawaiiMinting.convertItem(_nft1155Address, _tokenId, _amount, _timestamp, _sender, _adminSignedData, v, r, s);
    }

}

