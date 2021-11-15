//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
}

interface EtherRock {
    function giftRock (uint rockNumber, address receiver) external;
}

contract RockEscrow {
    address constant EmblemVault = 0x82C7a8f707110f5FBb16184A5933E9F78a34c6ab;
    uint constant rockEmblemId = 8681851;
    address constant etherRockContract = 0x41f28833Be34e6EDe3c58D1f597bef429861c4E2;
    uint constant etherRockNumber = 72;

    function withdrawRock() public {
        IERC721(EmblemVault).safeTransferFrom(msg.sender, address(this), rockEmblemId);
        EtherRock(etherRockContract).giftRock(etherRockNumber, msg.sender);
    }

    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) public returns(bytes4) {
        return this.onERC721Received.selector;
    } 
}

