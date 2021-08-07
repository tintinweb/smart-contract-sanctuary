/**
 *Submitted for verification at Etherscan.io on 2021-08-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

contract Test  {
    
    uint256 public purchaseNFTID;
    address public purchaseBuyer;

    uint256[] public purchaseparcelNFTIDS;
    address public purchaseparcelBuyer;

    address public mintRecipient;
    uint256 public mintX;
    uint256 public mintY;
    string public mintData;
    
    function purchaseProperty(uint256 nftId, address buyer)
        public
    {
        purchaseNFTID = nftId;
        purchaseBuyer = buyer;
    }

    function purchaseParcel(uint256[] memory nftIds, address buyer)
        external
    {
        purchaseparcelNFTIDS = nftIds;
        purchaseparcelBuyer = buyer;
    }

    function mintProperty(
        address recipient,
        uint256 x,
        uint256 y,
        string memory data
    ) external returns (uint256) {
        mintRecipient = recipient;
        mintX = x;
        mintY = y;
        mintData = data;
        return 1;
    }

}