/**
 *Submitted for verification at hecoinfo.com on 2022-05-04
*/

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

interface IERC721Enumerable {
    // function transferFrom(
    //     address from,
    //     address to,
    //     uint256 tokenId
    // ) external;
    function ownerOf(uint256 tokenId) external view returns (address owner);
    // function name() external view returns (string memory);
    // function symbol() external view returns (string memory);
    // function tokenURI(uint256 tokenId) external view returns (string memory);
    // function mintForMiner(address _to) external returns (bool, uint256);
    // function MinerList(address _address) external returns (bool);
}

interface coso is IERC721Enumerable {
    function swapFee() external view returns (uint256);

    function buybackPrice() external view returns (uint256);

    function buybackToken() external view returns (IERC20);

    function CanBuyBackList(address _user, uint256 _tokenId) external view returns (bool);
}

interface m0 {
    struct tokenInfo {
        string name;
        string symbol;
        uint256 decimal;
    }

    struct orderItem_1 {
        uint256 orderId;
        IERC721Enumerable nftToken;
        uint256 igoTotalAmount;
        address erc20Token;
        uint256 price;
        bool orderStatus;
        uint256 igoOkAmount;
        uint256 startBlock;
        uint256 endBlock;
        uint256 cosoQuote;
        bool useWhiteListCheck;
    }

    struct orderItem_2 {
        IERC20 swapToken;
        uint256 swapPrice;
        uint256 buyBackEndBlock;
        uint256 buyBackNum;
        uint256 swapFee;
        uint256 igoMaxAmount;
        IERC721Enumerable CosoNFT;
        bool useStakingCoso;
        bool useWhiteList;
        IERC20 ETH;
    }
}

interface IGOPool is m0 {
    function CanBuyBackList(address _user, uint256 _tokenId) external view returns (bool);

    function fk1() external view returns (orderItem_1 memory);

    function fk2() external view returns (orderItem_2 memory);
}

contract CanBuyBackForPoolList is m0 {
    struct canBuyBackItem {
        IGOPool IGOPoolAddress;
        bool InList;
        orderItem_1 fk1;
        orderItem_2 fk2;
    }

    function getCanBuyBack(IERC721Enumerable _nftToken, uint256 _tokenId, address _user, IGOPool[] memory igoPoolList) external view returns (bool canBuyBack1, canBuyBackItem[] memory canBuyBackArray) {
        canBuyBack1 = false;
        if (_nftToken.ownerOf(_tokenId) == _user) {
            canBuyBack1 = true;
        }
        canBuyBackArray = new canBuyBackItem[](igoPoolList.length);
        for (uint256 i = 0; i < igoPoolList.length; i++) {
            IGOPool IGOPoolItem = igoPoolList[i];
            bool canBuyBack2 = IGOPoolItem.CanBuyBackList(_user, _tokenId);
            orderItem_1  memory orderItem_1 = IGOPoolItem.fk1();
            orderItem_2  memory orderItem_2 = IGOPoolItem.fk2();
            canBuyBackArray[i] = canBuyBackItem({
            IGOPoolAddress : IGOPoolItem,
            InList : canBuyBack2,
            fk1 : orderItem_1,
            fk2 : orderItem_2
            });
        }
    }

    function getCanBuyBackForCoso(coso _nftToken, uint256 _tokenId, address _user) external view returns (bool canBuyBack1, bool canBuyBack2, uint256 swapFee, uint256 buybackPrice, IERC20 buybackToken, tokenInfo memory buybackTokenInfo) {
        canBuyBack1 = false;
        if (_nftToken.ownerOf(_tokenId) == _user) {
            canBuyBack1 = true;
        }
        canBuyBack2 = _nftToken.CanBuyBackList(_user, _tokenId);
        swapFee = _nftToken.swapFee();
        buybackPrice = _nftToken.buybackPrice();
        buybackToken = _nftToken.buybackToken();
        buybackTokenInfo = tokenInfo({
        name : buybackToken.name(),
        symbol : buybackToken.symbol(),
        decimal : buybackToken.decimals()
        });
    }
}