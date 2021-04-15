/**
 *Submitted for verification at Etherscan.io on 2021-04-15
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;



// Part: IERC1155

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

// Part: IERC20

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
}

// Part: IVendingMachine

interface IVendingMachine {
    /**
     * @dev Function for buying one or more of the same NFT id in a sale
     * @param saleId nft sale id
     * @param amount amount of tokenId to buy in saleId 
     */
    function buyNFT(uint256 saleId, uint256 amount) external payable;

    function sales(uint256 saleId) external view returns (
        address creator,
        address nft,
        uint256 tokenId,
        uint256 amountLeft,
        address tokenWant,
        uint256 pricePerUnit
    );
}

// File: DefiVilleMarket.sol

library DefiVilleMarket {
    address public constant VENDING_MACHINE = 0xA0Fd0f02797a9f38DF55Fe6ba0cF870e57D1A0e5;

    function buyAssetsForErc20(bytes memory data, address recipient) public {
        uint256[] memory saleIds;
        uint256[] memory amounts;

        (saleIds, amounts) = abi.decode(
            data,
            (uint256[],uint256[])
        );
        
        for (uint256 i = 0; i < saleIds.length; i++) {
            (, address nftAddr, uint256 tokenId, , address tokenWant, uint256 pricePerUnit) = IVendingMachine(VENDING_MACHINE).sales(saleIds[i]);

            tokenWant == address(0)
            ? _buyAssetForEth(saleIds[i], amounts[i], pricePerUnit*amounts[i], tokenId, nftAddr, recipient)
            : _buyAssetForErc20(saleIds[i], amounts[i], pricePerUnit*amounts[i], tokenId, nftAddr, tokenWant, recipient);
        }
    }

    function estimateBatchAssetPriceInErc20(bytes memory data) external view returns(address[] memory erc20Addrs, uint256[] memory erc20Amounts) {
        uint256[] memory saleIds;
        uint256[] memory amounts;

        (saleIds, amounts) = abi.decode(
            data,
            (uint256[],uint256[])
        );
        
        erc20Addrs = new address[](saleIds.length);
        erc20Amounts = new uint256[](amounts.length);

        for (uint256 i = 0; i < saleIds.length; i++) {
            (, , , uint256 amountLeft, address tokenWant, uint256 pricePerUnit) = IVendingMachine(VENDING_MACHINE).sales(saleIds[i]);
            
            if (amountLeft >= amounts[i]) {
                erc20Addrs[i] = tokenWant == address(0)
                ? 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
                : tokenWant;
                
                erc20Amounts[i] = pricePerUnit*amounts[i];
            }
        }
    }

    function _buyAssetForEth(uint256 _saleId, uint256 _amount, uint256 _tokenWantAmount, uint256 _tokenId, address _nftAddr, address _recipient) internal {
        bytes memory _data = abi.encodeWithSelector(IVendingMachine(VENDING_MACHINE).buyNFT.selector, _saleId, _amount);

        (bool success, ) = VENDING_MACHINE.call{value:_tokenWantAmount}(_data);
        require(success, "_buyAssetForEth: defiville buy failed.");
        
        IERC1155(_nftAddr).safeTransferFrom(address(this), _recipient, _tokenId, _amount, "");
    }

    function _buyAssetForErc20(uint256 _saleId, uint256 _amount, uint256 _tokenWantAmount, uint256 _tokenId, address _nftAddr, address _tokenWant, address _recipient) internal {
        IERC20(_tokenWant).approve(VENDING_MACHINE, _tokenWantAmount);
        IVendingMachine(VENDING_MACHINE).buyNFT(_saleId, _amount);
        IERC1155(_nftAddr).safeTransferFrom(address(this), _recipient, _tokenId, _amount, "");
    }
}