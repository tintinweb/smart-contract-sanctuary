/**
 *Submitted for verification at polygonscan.com on 2021-07-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
// import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract NftBalanceTest {
    
    ForgeToken forgeToken;
    address walletAddress;
    uint256 nftId;

    constructor(ForgeToken _forgeToken, uint256 _nftId) {
        forgeToken = _forgeToken;
        nftId = _nftId;
    }
    
    function getBalanceOf(address _walletAddress) external view returns (uint256) {
        return forgeToken.balanceOf(_walletAddress, nftId);
    }
}

interface ForgeToken {
    
    function balanceOf(address account, uint256 id) external view returns (uint256);
    
}