// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./NFTXv10.sol";

contract NFTXv11 is NFTXv10 {
    function revokeMintRequests(uint256 vaultId, uint256[] memory nftIds)
        public
        virtual
        override
        nonReentrant
    {
        for (uint256 i = 0; i < nftIds.length; i = i.add(1)) {
            require(
                store.requester(vaultId, nftIds[i]) == msg.sender,
                "Not requester"
            );
            store.setRequester(vaultId, nftIds[i], address(0));
            if (vaultId > 6 && vaultId < 10) {
                KittyCore kittyCore = KittyCore(store.nftAddress(vaultId));
                kittyCore.transfer(msg.sender, nftIds[i]);
            } else {
                store.nft(vaultId).safeTransferFrom(
                    address(this),
                    msg.sender,
                    nftIds[i]
                );
            }
        }
    }
}