// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

import "../../../../../interfaces/markets/tokens/IERC20.sol";
import "../../../../../interfaces/markets/tokens/IERC721.sol";

interface INFTX {
    function mint(
        uint256 vaultId, 
        uint256[] memory nftIds, 
        uint256 d2Amount
    ) external payable;

    // function redeem(
    //     uint256 vaultId,
    //     uint256 amount
    // ) external payable;
}

interface IWrappedPunk {
    /**
     * @dev Mints a wrapped punk
     */
    function mint(uint256 punkIndex) external;
    
    /**
     * @dev Registers proxy
     */
    function registerProxy() external;

    /**
     * @dev Gets proxy address
     */
    function proxyInfo(address user) external view returns (address);
}

interface ICryptoPunks {
    // Transfer ownership of a punk to another user without requiring payment
    function transferPunk(address to, uint punkIndex) external;
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

library NftxV1Market {
    address public constant NFTX = 0xAf93fCce0548D3124A5fC3045adAf1ddE4e8Bf7e;

    function _approve(
        address _operator, 
        address _token, 
        uint256[] memory _tokenIds
    ) internal {
        // in case of kitties
        if (_token == 0x06012c8cf97BEaD5deAe237070F9587f8E7A266d) {
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                IERC721(_token).approve(_operator, _tokenIds[i]);
            }
        }
        // default
        else if (!IERC721(_token).isApprovedForAll(address(this), _operator)) {
            IERC721(_token).setApprovalForAll(_operator, true);
        }
    }

    function sellERC721ForERC20Equivalent(
        uint256 vaultId,
        uint256[] memory tokenIds,
        address token
    ) external {
        _approve(NFTX, token, tokenIds);
        INFTX(NFTX).mint(vaultId, tokenIds, 0);
    }
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