/**
 *Submitted for verification at Etherscan.io on 2021-10-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface NftContract {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract Distributor {
    function distributeEth(address payable[] memory winners) public payable {
        uint256 length = winners.length;
        for (uint256 i = 0; i < length; i++) {
            bool success = false;
            (success,) = winners[i].call{value : msg.value/ length}("");
            require(success, "Failed to send1");
        }

    }
    
    function distributeNfts(address contractAddress, address[] memory winners, uint256[] memory nfts) public {
        require(winners.length == nfts.length, "revert");
        NftContract nftContract = NftContract(contractAddress);
        
        uint256 length = winners.length;
        for (uint256 i = 0; i < length; i++) {
            nftContract.transferFrom(msg.sender, winners[i], nfts[i]);
        }
    }
}