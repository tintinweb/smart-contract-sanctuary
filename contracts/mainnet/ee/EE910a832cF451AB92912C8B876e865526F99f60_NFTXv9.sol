// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./NFTXv8.sol";

interface KittyCore {
    function transfer(address _to, uint256 _tokenId) external;
}

contract NFTXv9 is NFTXv8 {
    function _redeemHelper(
        uint256 vaultId,
        uint256[] memory nftIds,
        bool isDualOp
    ) internal virtual override {
        store.xToken(vaultId).burnFrom(msg.sender, nftIds.length.mul(10**18));
        for (uint256 i = 0; i < nftIds.length; i = i.add(1)) {
            uint256 nftId = nftIds[i];
            require(store.holdingsContains(vaultId, nftId), "1");
            if (store.holdingsContains(vaultId, nftId)) {
                store.holdingsRemove(vaultId, nftId);
            }
            if (store.flipEligOnRedeem(vaultId)) {
                bool isElig = store.isEligible(vaultId, nftId);
                store.setIsEligible(vaultId, nftId, !isElig);
            }
            if (isVault1155[vaultId]) {
                IERC1155 nft = IERC1155(store.nftAddress(vaultId));
                nft.safeTransferFrom(address(this), msg.sender, nftId, 1, "");
            } else if (vaultId > 6 && vaultId < 10) {
                KittyCore kittyCore = KittyCore(store.nftAddress(vaultId));
                kittyCore.transfer(msg.sender, nftId);
            } else {
                store.nft(vaultId).safeTransferFrom(
                    address(this),
                    msg.sender,
                    nftId
                );
            }
        }
    }
}