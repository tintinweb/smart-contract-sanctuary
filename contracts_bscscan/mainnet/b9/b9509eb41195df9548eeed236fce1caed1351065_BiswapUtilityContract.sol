//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;

interface IBiswapNFT{
    function balanceOf(address user) external view returns(uint balance);
    function tokenOfOwnerByIndex(address user, uint tokenIndex) external view returns(uint tokenId);
    function getRB(uint tokenId) external view returns(uint RBBalance);
}

contract BiswapUtilityContract {
    function getTotalRBOfUser(address _user) public view returns (uint totalUserRbBalance) {
        IBiswapNFT biswapNFT = IBiswapNFT(0xD4220B0B196824C2F548a34C47D81737b0F6B5D6);
        uint userBalance = biswapNFT.balanceOf(_user);

        for (uint i = 0; i < userBalance; i++){
            uint tokenId = biswapNFT.tokenOfOwnerByIndex(_user, i);
            totalUserRbBalance += biswapNFT.getRB(tokenId);
        }
    }
}