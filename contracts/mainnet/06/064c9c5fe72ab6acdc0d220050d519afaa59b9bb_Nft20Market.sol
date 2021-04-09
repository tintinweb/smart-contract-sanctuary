/**
 *Submitted for verification at Etherscan.io on 2021-04-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC1155 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;
}

interface IERC721 {
    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external;
    
    function setApprovalForAll(address operator, bool approved) external;

    function approve(address to, uint256 tokenId) external;
    
    function isApprovedForAll(address owner, address operator) external returns (bool);
}

interface IERC20 {
    /**
        * @dev Returns the amount of tokens owned by `account`.
        */
    function balanceOf(address account) external view returns (uint256);

    /**
        * @dev Moves `amount` tokens from the caller's account to `recipient`.
        *
        * Returns a boolean value indicating whether the operation succeeded.
        *
        * Emits a {Transfer} event.
        */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);
}


interface INFT20Pair {
    function withdraw(
        uint256[] calldata _tokenIds,
        uint256[] calldata amounts,
        address recipient
    ) external;

    function withdraw(
        uint256[] calldata _tokenIds,
        uint256[] calldata amounts
    ) external;

    function track1155(uint256 _tokenId) external returns (uint256);

    function multi721Deposit(uint256[] memory _ids, address _referral) external;
}

interface INft20Registry {
    function nftToErc20(address nftAddr) external view returns (address erc20Addr);
}

library Nft20Market {

    struct NftDetails {
        address nftAddr;
        uint256[] tokenIds;
        uint256[] amounts;
    }

    INft20Registry public constant Nft20Registry = INft20Registry(0xB0244fDEf4E48c2bCBAcf10cC8dd07f0CB45E7Bf); 
    uint256 public constant NFT20_NFT_VALUE = 100 * 10**18;
    address public constant REFERRAL = 0x073Ab1C0CAd3677cDe9BDb0cDEEDC2085c029579;

    function _approve(address _operator, address _token) internal {
        if(!IERC721(_token).isApprovedForAll(address(this), _operator)) {
            IERC721(_token).setApprovalForAll(_operator, true);
        }
    }

    function sellERC721ForERC20Equivalent(
        bytes memory data
    ) external returns (address _erc20Address, uint256 _erc20Amount) {        
        address _fromERC721;
        uint256[] memory _ids;
        
        (_fromERC721, _ids) = abi.decode(
            data,
            (address, uint256[])
        );

        // NFT20 ERC20 for the _fromERC721
        _erc20Address = Nft20Registry.nftToErc20(_fromERC721);

        // save gas in case only a single ERC721 needs to be sold
        if(_ids.length == 1) {
            // transfer the token to NFT20 ERC20
            IERC721(_fromERC721).safeTransferFrom(
                address(this),
                _erc20Address,
                _ids[0],
                abi.encodePacked(REFERRAL) // referral
            );
        }
        // in case multiple ERC721(s) need to be sold
        else {
            // approve tokens to the NFT20 ERC20 contract
            _approve(_erc20Address, _fromERC721);
            // mint NFT20 ERC20 
            INFT20Pair(_erc20Address).multi721Deposit(
                _ids,
                REFERRAL // referral
            );
        }

        return (
            _erc20Address,
            IERC20(_erc20Address).balanceOf(address(this))
        );
    }

    function sellERC1155ForERC20Equivalent(
        bytes memory data
    ) external returns (address _erc20Address, uint256 _erc20Amount) {
        address _fromERC1155;
        uint256 _id;
        uint256 _amount;
        
        (_fromERC1155, _id, _amount) = abi.decode(
            data,
            (address, uint256, uint256)
        );

        // NFT20 ERC20 for the _fromERC1155
        _erc20Address = Nft20Registry.nftToErc20(_fromERC1155);

        // transfer the token to NFT20 ERC20
        IERC1155(_fromERC1155).safeTransferFrom(
            address(this),
            _erc20Address,
            _id,
            _amount,
            abi.encodePacked(REFERRAL) // referral
        );
        return (
            _erc20Address,
            IERC20(_erc20Address).balanceOf(address(this))
        );
    }

    function sellERC1155BatchForERC20Equivalent(
        bytes memory data
    ) external returns (address _erc20Address, uint256 _erc20Amount) {
        address _fromERC1155;
        uint256[] memory _ids;
        uint256[] memory _amounts;

        (_fromERC1155, _ids, _amounts) = abi.decode(
            data,
            (address, uint256[], uint256[])
        );

        // NFT20 ERC20 for the _fromERC1155
        _erc20Address = Nft20Registry.nftToErc20(_fromERC1155);

        // transfer the tokens to NFT20 ERC20
        IERC1155(_fromERC1155).safeBatchTransferFrom(
            address(this),
            _erc20Address,
            _ids,
            _amounts,
            abi.encodePacked(REFERRAL) // referral
        );
        return (
            _erc20Address,
            IERC20(_erc20Address).balanceOf(address(this))
        );
    }

    function buyAssetsForErc20(bytes memory data, address recipient) external {
        address _nftAddr;
        address _fromERC20;
        uint256[] memory _ids;
        uint256[] memory _amounts;
        
        (_nftAddr, _fromERC20, _ids, _amounts) = abi.decode(
            data,
            (address, address, uint256[], uint256[])
        );

        // Handle special cases where we cannot directly send NFTs to the recipient
        if(
            _fromERC20 == 0x22C4AD011Cce6a398B15503e0aB64286568933Ed || // Doki Doki
            _fromERC20 == 0x303Af77Cf2774AABff12462C110A0CCf971D7DbE || // Node Runners
            _fromERC20 == 0xaDBEBbd65a041E3AEb474FE9fe6939577eB2544F || // Chonker Finance
            _fromERC20 == 0x57C31c042Cb2F6a50F3dA70ADe4fEE20C86B7493    // Block Art         
        ) {
            for(uint256 i = 0; i < _ids.length; i++) {
                uint256[] memory _tempIds = new uint256[](1);
                uint256[] memory _tempAmounts = new uint256[](1);
                _tempIds[0] =  _ids[i];
                _tempAmounts[0] =  _amounts[i];
                INFT20Pair(_fromERC20).withdraw(_tempIds, _tempAmounts);
                
                // transfer the ERC721 to the recipient
                if(_fromERC20 == 0x57C31c042Cb2F6a50F3dA70ADe4fEE20C86B7493) {
                    IERC721(_nftAddr).transferFrom(address(this), recipient, _ids[i]);
                }
            }
            // transfer the ERC1155 to the recipient
            IERC1155(_nftAddr).safeBatchTransferFrom(address(this), recipient, _ids, _amounts, "");
        }
        // send NFTs to the recipient
        else {
            INFT20Pair(_fromERC20).withdraw(_ids, _amounts, recipient);
        }
    }

    function estimateBatchAssetPriceInErc20(bytes memory data) public view returns(address[] memory erc20Addrs, uint256[] memory erc20Amounts) {
        // get nft details
        NftDetails[] memory nftDetails;
        (nftDetails) = abi.decode(
            data,
            (NftDetails[])
        );

        // initialize return variables
        erc20Addrs = new address[](nftDetails.length); 
        erc20Amounts = new uint256[](nftDetails.length);

        for (uint256 i = 0; i < nftDetails.length; i++) {
            // populate equivalent ERC20 
            erc20Addrs[i] = Nft20Registry.nftToErc20(nftDetails[i].nftAddr);
            // nft should be supported
            require(erc20Addrs[i] != address(0), "estimateBatchAssetPriceInErc20: unsupported nft");
            // calculate token amount needed
            for (uint256 j = 0; j < nftDetails[i].tokenIds.length; j++) {
                erc20Amounts[i] = erc20Amounts[i] + nftDetails[i].amounts[j]*NFT20_NFT_VALUE;
            }
        }
    }
}