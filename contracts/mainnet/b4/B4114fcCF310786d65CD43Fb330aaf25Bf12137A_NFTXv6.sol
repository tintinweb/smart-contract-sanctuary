// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./NFTXv5.sol";
import "./IXTokenFactory.sol";

contract NFTXv6 is NFTXv5 {
    function changeTokenName(uint256 vaultId, string memory newName)
        public
        virtual
        override
    {}

    function changeTokenSymbol(uint256 vaultId, string memory newSymbol)
        public
        virtual
        override
    {}

    /* function setSupplierBounty(uint256 vaultId, uint256 ethMax, uint256 length)
        public
        virtual
        override
    {} */

    /* IXTokenFactory public xTokenFactory; */

    /* function setXTokenFactoryAddress(address a) public onlyOwner {
      xTokenFactory = IXTokenFactory(a);
    } */

    function createVault(
        address _xTokenAddress,
        address _assetAddress,
        bool _isD2Vault
    ) public virtual override nonReentrant returns (uint256) {
        return 99999;
    }

    function createVault(
        string memory name,
        string memory symbol,
        address _assetAddress,
        bool _isD2Vault
    ) public virtual nonReentrant returns (uint256) {
        onlyOwnerIfPaused(0);
        IXTokenFactory xTokenFactory = IXTokenFactory(
            0xE7ac17cE2550f3a0B4fE3616515975eb093CEfea
        );
        address xTokenAddress = xTokenFactory.createXToken(name, symbol);
        uint256 vaultId = store.addNewVault();
        store.setXTokenAddress(vaultId, xTokenAddress);
        store.setXToken(vaultId);
        if (!_isD2Vault) {
            store.setNftAddress(vaultId, _assetAddress);
            store.setNft(vaultId);
            store.setNegateEligibility(vaultId, true);
        } else {
            store.setD2AssetAddress(vaultId, _assetAddress);
            store.setD2Asset(vaultId);
            store.setIsD2Vault(vaultId, true);
        }
        store.setManager(vaultId, msg.sender);
        emit NewVault(vaultId, msg.sender);
        return vaultId;
    }

    /* function redeemD1For(
        uint256 vaultId,
        uint256 amount,
        uint256[] memory nftIds,
        address recipient
    ) public payable virtual nonReentrant {
        onlyOwnerIfPaused(2);
        _redeemHelperFor(vaultId, nftIds, false, recipient);
        emit Redeem(vaultId, nftIds, 0, msg.sender);
    }

    function _redeemHelper(
        uint256 vaultId,
        uint256[] memory nftIds,
        bool isDualOp
    ) internal virtual override {
        _redeemHelperFor(vaultId, nftIds, isDualOp, msg.sender);
    }

    function _redeemHelperFor(
        uint256 vaultId,
        uint256[] memory nftIds,
        bool isDualOp,
        address recipient
    ) internal virtual {
        if (!isDualOp) {
            store.xToken(vaultId).burnFrom(
                msg.sender,
                nftIds.length.mul(10**18)
            );
        }
        for (uint256 i = 0; i < nftIds.length; i = i.add(1)) {
            uint256 nftId = nftIds[i];
            require(
                store.holdingsContains(vaultId, nftId) ||
                    store.reservesContains(vaultId, nftId),
                "NFT not in vault"
            );
            if (store.holdingsContains(vaultId, nftId)) {
                store.holdingsRemove(vaultId, nftId);
            } else {
                store.reservesRemove(vaultId, nftId);
            }
            if (store.flipEligOnRedeem(vaultId)) {
                bool isElig = store.isEligible(vaultId, nftId);
                store.setIsEligible(vaultId, nftId, !isElig);
            }
            store.nft(vaultId).safeTransferFrom(
                address(this),
                recipient,
                nftId
            );
        }
    } */

}