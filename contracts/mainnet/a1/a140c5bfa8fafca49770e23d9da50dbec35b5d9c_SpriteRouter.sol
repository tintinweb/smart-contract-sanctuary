/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

//SPDX-License-Identifier: AGPL-3.0-only

// Dear Deer NFT sprite router

// Provides 72x72 raster sprites for Dear Deer render functions from onchain storages

// Main contract address: 0x108578c96C61f3e5a3a12d43d42A60346a6Bfcb2

/*
*     \_\_     _/_/
*         \___/
*        ~(0 0)~
*         (._.)\_________
*             \          \~
*              \  _____(  )
*               ||      ||
*               ||      ||
*
*/

pragma solidity 0.8.9;

interface ISpriteStorage {
    function getSprite(uint8 partId, uint8 typeId, uint8 spriteId) external view returns (string memory);
}

contract SpriteRouter {

    address owner;

    ISpriteStorage spriteStorage0;
    ISpriteStorage spriteStorage1;
    ISpriteStorage spriteStorage2;
    ISpriteStorage spriteStorage3;
    ISpriteStorage spriteStorage4;
    ISpriteStorage spriteStorage5;
    ISpriteStorage spriteStorage6;
    ISpriteStorage spriteStorage7;

    string constant PNG_HEADER = "iVBORw0KGgoAAAANSUhEUgAAAEgAAABI";
    string constant PNG_HEADER_BG = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABAQMAAAAl21bKAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAAADUExUR";

    constructor() {
        owner = msg.sender;
    }

    function getSprite(uint8 partId, uint8 typeId, uint8 spriteId) external view returns (string memory) {
        string memory spriteHeader;
        string memory spriteData;
        spriteHeader = partId == 0 ? PNG_HEADER_BG : PNG_HEADER;
        
        if (partId <= 2) {
            spriteData = spriteStorage0.getSprite(partId, typeId, spriteId);
        } else if (partId == 3) {
            spriteData = spriteStorage1.getSprite(partId, typeId, spriteId);
        } else if (partId == 4) {
            if (typeId <= 4) {
                spriteData = spriteStorage2.getSprite(partId, typeId, spriteId);
            } else if (typeId >= 5 && typeId <= 10) {
                spriteData = spriteStorage3.getSprite(partId, typeId, spriteId);
            }
        } else if (partId >= 5 && partId <= 7) {
            spriteData = spriteStorage4.getSprite(partId, typeId, spriteId);
        } else if (partId == 8) {
            spriteData = spriteStorage5.getSprite(partId, typeId, spriteId);
        } else if (partId == 9) {
            spriteData = spriteStorage6.getSprite(partId, typeId, spriteId);
        } else if (partId >= 10 && partId<= 13) {
            spriteData = spriteStorage7.getSprite(partId, typeId, spriteId);
        }

        return string(
            abi.encodePacked(
                spriteHeader,
                spriteData
            )
        );
    }

    function setStorages(address[8] memory storageAddresses) external onlyOwner {
        // 0 background, 1 body, 2 freckles
        spriteStorage0 = ISpriteStorage(storageAddresses[0]);

        // 3 brows
        spriteStorage1 = ISpriteStorage(storageAddresses[1]);

        // 4 hair: 0 black, 1 blonde, 2 brown, 3 bubblegum, 4 night
        spriteStorage2 = ISpriteStorage(storageAddresses[2]);

        // 4 hair: 5 purple, 6 red, 7 shameless, 8 shosa, 9 swampy, 10 white
        spriteStorage3 = ISpriteStorage(storageAddresses[3]);

        // 5 ears, 6 earrings, 7 eyes
        spriteStorage4 = ISpriteStorage(storageAddresses[4]);

        // 8 clothes
        spriteStorage5 = ISpriteStorage(storageAddresses[5]);

        // 9 beard
        spriteStorage6 = ISpriteStorage(storageAddresses[6]);

        // 10 mouth, 11 nose, 12 antlers, 13 antler_accessory 
        spriteStorage7 = ISpriteStorage(storageAddresses[7]);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner lmao");
        _;
    }

}