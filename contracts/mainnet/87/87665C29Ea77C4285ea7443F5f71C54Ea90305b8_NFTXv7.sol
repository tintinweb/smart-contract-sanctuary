// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./NFTXv6.sol";
import "./IERC20.sol";
import "./IERC1155.sol";
import "./IERC1155Receiver.sol";

contract NFTXv7 is NFTXv6, IERC1155Receiver {

    mapping(uint256 => bool) public isVault1155;

    function setIs1155(
        uint256 vaultId,
        bool _boolean
    ) public virtual {
        onlyPrivileged(vaultId);
        isVault1155[vaultId] = _boolean;
    }

    function _mint(uint256 vaultId, uint256[] memory nftIds, bool isDualOp)
        internal
        virtual
        override
    {
        for (uint256 i = 0; i < nftIds.length; i = i.add(1)) {
            uint256 nftId = nftIds[i];
            require(isEligible(vaultId, nftId), "1");
            
            if (isVault1155[vaultId]) {
                IERC1155 nft = IERC1155(store.nftAddress(vaultId));
                nft.safeTransferFrom(msg.sender, address(this), nftId, 1, "");
            } else {
                require(
                    store.nft(vaultId).ownerOf(nftId) != address(this),
                    "2"
                );
                store.nft(vaultId).transferFrom(msg.sender, address(this), nftId);
                require(
                    store.nft(vaultId).ownerOf(nftId) == address(this),
                    "3"
                );
            }
            
            store.holdingsAdd(vaultId, nftId);
        }
        store.xToken(vaultId).mint(msg.sender, nftIds.length.mul(10**18));
    }

    function _redeemHelper(
        uint256 vaultId,
        uint256[] memory nftIds,
        bool isDualOp
    ) internal virtual override {
        store.xToken(vaultId).burnFrom(msg.sender, nftIds.length.mul(10**18));
        for (uint256 i = 0; i < nftIds.length; i = i.add(1)) {
            uint256 nftId = nftIds[i];
            require(
                store.holdingsContains(vaultId, nftId),
                "1"
            );
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
            } else {
                store.nft(vaultId).safeTransferFrom(
                    address(this),
                    msg.sender,
                    nftId
                );
            }
            
        }
    }

    function requestMint(uint256 vaultId, uint256[] memory nftIds)
        public
        payable
        virtual
        override
        nonReentrant
    {
        onlyOwnerIfPaused(1);
        require(store.allowMintRequests(vaultId), "1");
        // TODO: implement bounty + fees
        for (uint256 i = 0; i < nftIds.length; i = i.add(1)) {
            require(
                store.nft(vaultId).ownerOf(nftIds[i]) != address(this),
                "2"
            );
            store.nft(vaultId).safeTransferFrom(
                msg.sender,
                address(this),
                nftIds[i]
            );
            require(
                store.nft(vaultId).ownerOf(nftIds[i]) == address(this),
                "3"
            );
            store.setRequester(vaultId, nftIds[i], msg.sender);
        }
        emit MintRequested(vaultId, nftIds, msg.sender);
    }

    function setNegateEligibility(uint256 vaultId, bool shouldNegate)
        public
        virtual
        override
    {
        onlyPrivileged(vaultId);
        require(
            store
                .holdingsLength(vaultId)
                .add(store.d2Holdings(vaultId)) ==
                0,
            "1"
        );
        store.setNegateEligibility(vaultId, shouldNegate);
    }

    function mint(uint256 vaultId, uint256[] memory nftIds, uint256 d2Amount)
        public
        payable
        virtual
        override
        nonReentrant
    {
        onlyOwnerIfPaused(1);
        // uint256 amount = store.isD2Vault(vaultId) ? d2Amount : nftIds.length;
        // uint256 ethBounty = store.isD2Vault(vaultId)
        //     ? _calcBountyD2(vaultId, d2Amount, false)
        //     : _calcBounty(vaultId, amount, false);
        // (uint256 ethBase, uint256 ethStep) = store.mintFees(vaultId);
        // uint256 ethFee = _calcFee(
        //     amount,
        //     ethBase,
        //     ethStep,
        //     store.isD2Vault(vaultId)
        // );
        // if (ethFee > ethBounty) {
        //     _receiveEthToVault(vaultId, ethFee.sub(ethBounty), msg.value);
        // }
        if (store.isD2Vault(vaultId)) {
            _mintD2(vaultId, d2Amount);
        } else {
            _mint(vaultId, nftIds, false);
        }
        // if (ethBounty > ethFee) {
        //     _payEthFromVault(vaultId, ethBounty.sub(ethFee), msg.sender);
        // }
        emit Mint(vaultId, nftIds, d2Amount, msg.sender);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId)
        external
        override
        view
        returns (bool)
    {}

    function createVault(
        address _xTokenAddress,
        address _assetAddress,
        bool _isD2Vault
    ) public virtual override nonReentrant returns (uint256) {
        revert();
    }

    function setMintFees(uint256 vaultId, uint256 _ethBase, uint256 _ethStep)
        public
        virtual
        override
    {
        revert();
    }

    function setBurnFees(uint256 vaultId, uint256 _ethBase, uint256 _ethStep)
        public
        virtual
        override
    {
        revert();
    }

    function setSupplierBounty(uint256 vaultId, uint256 ethMax, uint256 length)
        public
        virtual
        override
    {
        revert();
    }

    mapping(uint256 => uint256) public rangeStart;
    mapping(uint256 => uint256) public rangeEnd;

    function setRange(
        uint256 vaultId,
        uint256 start,
        uint256 end
    ) public virtual {
        onlyPrivileged(vaultId);
        rangeStart[vaultId] = start;
        rangeEnd[vaultId] = end;
    }

    function isEligible(uint256 vaultId, uint256 nftId)
        public
        view
        virtual
        override
        returns (bool)
    {
        if (rangeEnd[vaultId] > 0) {
            if (nftId >= rangeStart[vaultId] && nftId <= rangeEnd[vaultId]) {
                return true;
            }
        }
        return
            store.negateEligibility(vaultId)
                ? !store.isEligible(vaultId, nftId)
                : store.isEligible(vaultId, nftId);
        
    }
}