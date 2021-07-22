// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;


import "../../../../../interfaces/markets/tokens/IERC1155.sol";
import "../../../../../interfaces/markets/tokens/IERC20.sol";
import "../../../../../interfaces/markets/tokens/IERC721.sol";

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

    function multi721Deposit(
        uint256[] memory _ids, 
        address _recipient,
        address _referral
    ) external;

    function swap721(uint256 _in, uint256 _out, address _recipient) external;

    function swap1155(
        uint256[] calldata in_ids,
        uint256[] calldata in_amounts,
        uint256[] calldata out_ids,
        uint256[] calldata out_amounts,
        address _recipient
    ) external;
}

interface INFT20Factory {
    function nftToToken(address pair) external view returns (address);
}

interface IMoonCatsWrapped {
    function wrap(bytes5 catId) external;
    function _catIDToTokenID(bytes5 catId) external view returns(uint256);
}

interface IMoonCatsRescue {
    /* puts a cat up for a specific address to adopt */
    function makeAdoptionOfferToAddress(bytes5 catId, uint price, address to) external;

    function rescueOrder(uint256 rescueIndex) external view returns(bytes5);
}

interface IMoonCatAcclimator {
    /**
     * @dev Take a list of MoonCats wrapped in this contract and unwrap them.
     * @param _rescueOrders an array of MoonCats, identified by rescue order, to unwrap
     */
    function batchUnwrap(uint256[] memory _rescueOrders) external;
}

library Nft20Market {

    function _approve(address _operator, address _token) internal {
        if(!IERC721(_token).isApprovedForAll(address(this), _operator)) {
            IERC721(_token).setApprovalForAll(_operator, true);
        }
    }

    function sellERC721ForERC20Equivalent(
        address _fromERC721,
        address _fromERC20,
        uint256[] memory _ids
    ) external {
        // save gas in case only a single ERC721 needs to be sold
        if(_ids.length == 1) {
            // transfer the token to NFT20 ERC20
            IERC721(_fromERC721).safeTransferFrom(
                address(this),
                _fromERC20,
                _ids[0],
                abi.encodePacked(address(this), address(this)) // referral, recipient
            );
        }
        // in case multiple ERC721(s) need to be sold
        else {
            // approve tokens to the NFT20 ERC20 contract
            _approve(_fromERC20, _fromERC721);
            // mint NFT20 ERC20 
            INFT20Pair(_fromERC20).multi721Deposit(
                _ids,
                address(this), // recipient
                address(this) // referral
            );
        }
    }

    function sellERC1155BatchForERC20Equivalent(
        address _fromERC1155,
        address _fromERC20,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) external {
        // transfer the tokens to NFT20 ERC20
        IERC1155(_fromERC1155).safeBatchTransferFrom(
            address(this),
            _fromERC20,
            _ids,
            _amounts,
            abi.encodePacked(address(this), address(this)) // referral, recipient
        );
    }

    function buyAssetsForErc20(
        address _nftAddr,
        address _fromERC20,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        address recipient
    ) external {
        // Handle special cases where we cannot directly send NFTs to the recipient
        if(
            _fromERC20 == 0x22C4AD011Cce6a398B15503e0aB64286568933Ed || // Doki Doki
            _fromERC20 == 0x303Af77Cf2774AABff12462C110A0CCf971D7DbE || // Node Runners
            _fromERC20 == 0xaDBEBbd65a041E3AEb474FE9fe6939577eB2544F || // Chonker Finance
            _fromERC20 == 0x57C31c042Cb2F6a50F3dA70ADe4fEE20C86B7493    // Block Art         
        ) {
            // redeem the NFTs
            INFT20Pair(_fromERC20).withdraw(_ids, _amounts);
            // transfer the ERC721 to the recipient
            if(_fromERC20 == 0x57C31c042Cb2F6a50F3dA70ADe4fEE20C86B7493) {
                for(uint256 i = 0; i < _ids.length; i++) {
                    IERC721(_nftAddr).transferFrom(address(this), recipient, _ids[i]);
                }
            }
            // transfer the ERC1155 to the recipient
            else {
                IERC1155(_nftAddr).safeBatchTransferFrom(address(this), recipient, _ids, _amounts, "");
            }
        }
        // send NFTs to the recipient
        else {
            INFT20Pair(_fromERC20).withdraw(_ids, _amounts, recipient);
        }
    }

    function swapErc721(
        address nftAddr, 
        address fromERC20,
        uint256[] memory fromTokenId, 
        uint256[] memory toTokenId,
        address recipient
    ) external {
        // approve token to NFT20 pool
        _approve(fromERC20, nftAddr);
        // swap tokens and send back to recipient
        for (uint256 i = 0; i < fromTokenId.length; i++) {
            INFT20Pair(fromERC20).swap721(fromTokenId[i], toTokenId[i], recipient);
        }
    }

    function swapErc1155(
        address nftAddr, 
        address fromERC20,
        uint256[] calldata fromTokenIds,
        uint256[] calldata fromAmounts,
        uint256[] calldata toTokenIds,
        uint256[] calldata toAmounts,
        address recipient
    ) external {
        // approve token to NFT20 pool
        _approve(fromERC20, nftAddr);
        // swap tokens and send back to recipient
        INFT20Pair(fromERC20).swap1155(fromTokenIds, fromAmounts, toTokenIds, toAmounts, recipient);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

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

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

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
    
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}